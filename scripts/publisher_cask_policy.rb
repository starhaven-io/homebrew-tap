# typed: strict
# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "tmpdir"
require "uri"
require "rubygems/version"

# Validates automated cask updates without evaluating proposed Ruby code.
module PublisherCaskPolicy
  BOT_USER_ID = "274951094"
  TAP_REPOSITORY = "starhaven-io/homebrew-tap"
  OWNER = "starhaven-io"
  PRODUCTS = {
    "brewy"    => "Brewy",
    "macosdb"  => "macOSdb",
    "midden"   => "midden",
    "pinprick" => "pinprick",
  }.freeze
  TOKEN_PATTERN = /\A[a-z0-9][a-z0-9_.+-]*\z/
  CASK_PATH_PATTERN = %r{\ACasks/([a-z0-9][a-z0-9_.+-]*)\.rb\z}
  VERSION_PATTERN = /\A[0-9]+(?:\.[0-9]+)*\z/
  SHA256_PATTERN = /[0-9a-f]{64}/
  ASSET_NAME_PATTERN = /\A[A-Za-z0-9][A-Za-z0-9._+-]*\z/
  VERSION_PLACEHOLDER = "\#{version}"
  MAX_CASK_BYTES = 64 * 1024

  class PolicyError < StandardError; end

  # Parses the two cask layouts supported by this tap into immutable asset bindings.
  class SourceParser
    VERSION_PATTERN = /^(?<prefix>[ \t]*version[ \t]+)"(?<value>[^"\r\n]+)"[ \t]*$/
    URL_PATTERN = Regexp.new(
      '^[ \t]*url[ \t]+"(?<url>[^"\r\n]+)"(?<comma>,?)[ \t]*' \
      '(?:\n[ \t]+verified:[ \t]+"(?<verified>[^"\r\n]+)"[ \t]*)?$',
    ).freeze
    PLAIN_SHA_PATTERN = /^[ \t]*sha256[ \t]+"(?<digest>#{SHA256_PATTERN})"[ \t]*$/
    KEYED_SHA_PATTERN = Regexp.new(
      "^[ \\t]*sha256[ \\t]+arm64_linux:[ \\t]+\"(?<arm64>#{SHA256_PATTERN})\",[ \\t]*\\n" \
      "[ \\t]+x86_64_linux:[ \\t]+\"(?<x86_64>#{SHA256_PATTERN})\"[ \\t]*$",
    ).freeze
    ARCH_PATTERN = /^  arch arm: "(?<arm>[^"]+)", intel: "(?<intel>[^"]+)"[ \t]*$/
    OS_PATTERN = /^  os macos: "(?<macos>[^"]+)", linux: "(?<linux>[^"]+)"[ \t]*$/

    def initialize(source, token)
      @source = source.dup.force_encoding(Encoding::UTF_8)
      @token = token
    end

    def parse
      validate_source!
      version_match = exactly_one_match(VERSION_PATTERN, "literal version")
      url_match = exactly_one_match(URL_PATTERN, "literal URL")
      plain_matches = scan_matches(PLAIN_SHA_PATTERN)
      keyed_matches = scan_matches(KEYED_SHA_PATTERN)
      validate_sha_matches!(plain_matches, keyed_matches)

      normalized = normalize(version_match, plain_matches, keyed_matches)
      url_details = parse_url(url_match)
      bindings = build_bindings(url_details.fetch(:asset_template), plain_matches, keyed_matches)

      {
        version:    version_match[:value],
        normalized: normalized,
        repository: url_details.fetch(:repository),
        tag:        render(url_details.fetch(:tag_template), version: version_match[:value]),
        artifacts:  bindings,
      }
    end

    private

    def validate_source!
      raise PolicyError, "Cask source is not valid UTF-8: #{@token}" unless @source.valid_encoding?
      raise PolicyError, "Cask source must end with one newline: #{@token}" unless @source.end_with?("\n")
      if @source.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/)
        raise PolicyError,
              "Cask source contains unsupported control characters: #{@token}"
      end

      declarations = scan_matches(/^cask "([^"]+)" do[ \t]*$/)
      raise PolicyError, "Cask source must contain one declaration: #{@token}" if declarations.length != 1
      raise PolicyError, "Cask declaration does not match path: #{@token}" if declarations.first[1] != @token
      raise PolicyError, "Cask declaration must be the first line: #{@token}" unless declarations.first.begin(0).zero?
    end

    def exactly_one_match(pattern, description)
      matches = scan_matches(pattern)
      raise PolicyError, "Cask source must contain one #{description}: #{@token}" if matches.length != 1

      matches.first
    end

    def scan_matches(pattern)
      @source.enum_for(:scan, pattern).map { Regexp.last_match.dup }
    end

    def validate_sha_matches!(plain_matches, keyed_matches)
      parsed_stanzas = plain_matches.length + keyed_matches.length
      source_stanzas = @source.scan(/^[ \t]*sha256\b/).length
      return if parsed_stanzas.positive? && parsed_stanzas == source_stanzas

      raise PolicyError, "Cask source contains an unsupported sha256 stanza: #{@token}"
    end

    def normalize(version_match, plain_matches, keyed_matches)
      replacements = [[version_match.begin(:value), version_match.end(:value), "<VERSION>"]]
      plain_matches.each do |match|
        replacements << [match.begin(:digest), match.end(:digest), "<SHA256>"]
      end
      keyed_matches.each do |match|
        replacements << [match.begin(:arm64), match.end(:arm64), "<SHA256>"]
        replacements << [match.begin(:x86_64), match.end(:x86_64), "<SHA256>"]
      end

      normalized = @source.dup
      replacements.sort_by(&:first).reverse_each do |start_offset, end_offset, replacement|
        normalized[start_offset...end_offset] = replacement
      end
      normalized
    end

    def parse_url(match)
      verified = match[:verified]
      comma = match[:comma]
      if verified.nil? != comma.empty?
        raise PolicyError, "Cask URL has an unsupported verified form: #{@token}"
      end

      product = PRODUCTS.fetch(@token)
      expected_repository = "#{OWNER}/#{product}"
      prefix = "https://github.com/#{expected_repository}/releases/download/"
      url = match[:url]
      raise PolicyError, "Cask URL is not bound to #{expected_repository}: #{@token}" unless url.start_with?(prefix)

      if verified && verified != "github.com/#{expected_repository}/"
        raise PolicyError, "Cask verified host is not bound to #{expected_repository}: #{@token}"
      end

      tag_template, asset_template = url.delete_prefix(prefix).split("/", 2)
      unless [VERSION_PLACEHOLDER, "v#{VERSION_PLACEHOLDER}"].include?(tag_template)
        raise PolicyError, "Cask release tag must derive only from version: #{@token}"
      end
      raise PolicyError, "Cask release asset template is missing: #{@token}" if asset_template.nil?

      {
        repository:     expected_repository,
        tag_template:   tag_template,
        asset_template: asset_template,
      }
    end

    def build_bindings(asset_template, plain_matches, keyed_matches)
      placeholders = asset_template.scan(/#\{([^}]+)\}/).flatten
      if placeholders == ["version"]
        return build_single_binding(asset_template, plain_matches, keyed_matches)
      end

      if placeholders.sort != %w[arch os version]
        raise PolicyError, "Cask release asset placeholders are unsupported: #{@token}"
      end

      build_platform_bindings(asset_template, plain_matches, keyed_matches)
    end

    def build_single_binding(asset_template, plain_matches, keyed_matches)
      single_checksum = plain_matches.length == 1 && keyed_matches.empty? &&
                        block_range("on_macos").nil? && block_range("on_linux").nil?
      unless single_checksum
        raise PolicyError, "Single-asset cask must have one top-level checksum: #{@token}"
      end

      [
        artifact(
          "default",
          render(asset_template, version: version_value),
          plain_matches.first[:digest],
        ),
      ]
    end

    def build_platform_bindings(asset_template, plain_matches, keyed_matches)
      arch = exactly_one_match(ARCH_PATTERN, "literal arch mapping")
      os = exactly_one_match(OS_PATTERN, "literal OS mapping")
      macos_range = block_range("on_macos")
      linux_range = block_range("on_linux")
      if macos_range.nil? || linux_range.nil?
        raise PolicyError,
              "Platform cask requires on_macos and on_linux blocks: #{@token}"
      end

      macos_sha = plain_matches.select { |match| range_covers?(macos_range, match.begin(0)) }
      linux_sha = keyed_matches.select { |match| range_covers?(linux_range, match.begin(0)) }
      if macos_sha.length != 1 || linux_sha.length != 1 || plain_matches.length != 1 || keyed_matches.length != 1
        raise PolicyError, "Platform checksums are not bound to their OS blocks: #{@token}"
      end

      macos_body = @source[macos_range]
      unless macos_body.match?(/^    depends_on arch: :arm64[ \t]*$/)
        raise PolicyError, "macOS checksum requires an arm64 constraint: #{@token}"
      end

      values = {
        version:      version_value,
        macos_arm64:  { arch: arch[:arm], os: os[:macos], sha256: macos_sha.first[:digest] },
        linux_arm64:  { arch: arch[:arm], os: os[:linux], sha256: linux_sha.first[:arm64] },
        linux_x86_64: { arch: arch[:intel], os: os[:linux], sha256: linux_sha.first[:x86_64] },
      }
      artifacts = [:macos_arm64, :linux_arm64, :linux_x86_64].map do |selector|
        platform = values.fetch(selector)
        artifact(
          selector.to_s,
          render(
            asset_template,
            version: values.fetch(:version),
            arch:    platform.fetch(:arch),
            os:      platform.fetch(:os),
          ),
          platform.fetch(:sha256),
        )
      end
      raise PolicyError, "Cask selectors resolve to duplicate release assets: #{@token}" if artifacts.map do |item|
        item.fetch("name")
      end.uniq.length != artifacts.length

      artifacts
    end

    def version_value
      exactly_one_match(VERSION_PATTERN, "literal version")[:value]
    end

    def block_range(name)
      opening = "  #{name} do\n"
      lines = @source.lines
      offsets = []
      offset = 0
      lines.each do |line|
        offsets << offset
        offset += line.length
      end

      indexes = lines.each_index.select { |index| lines[index] == opening }
      return if indexes.empty?
      raise PolicyError, "Cask source contains multiple #{name} blocks: #{@token}" if indexes.length != 1

      start_index = indexes.first
      end_index = ((start_index + 1)...lines.length).find { |index| lines[index] == "  end\n" }
      raise PolicyError, "Cask source has an unterminated #{name} block: #{@token}" unless end_index

      body_start = offsets.fetch(start_index) + lines.fetch(start_index).length
      body_end = offsets.fetch(end_index)
      body_start...body_end
    end

    def range_covers?(range, offset)
      offset >= range.begin && offset < range.end
    end

    def render(template, values)
      rendered = template.gsub(/#\{([^}]+)\}/) do
        key = Regexp.last_match(1).to_sym
        raise PolicyError, "Unsupported release asset placeholder: #{key}" unless values.key?(key)

        values.fetch(key)
      end
      unless rendered.match?(ASSET_NAME_PATTERN)
        raise PolicyError, "Unsafe release asset name for #{@token}: #{rendered}"
      end

      rendered
    end

    def artifact(selector, name, sha256)
      { "selector" => selector, "name" => name, "sha256" => sha256 }
    end
  end

  # Wraps the GitHub CLI with argument-safe API, download, and attestation calls.
  class GitHubClient
    def release(repository, tag)
      api_json("/repos/#{repository}/releases/tags/#{encode_path_component(tag)}")
    end

    def resolve_tag_commit(repository, tag)
      object = api_json("/repos/#{repository}/git/ref/tags/#{encode_path_component(tag)}").fetch("object")
      5.times do
        type = object.fetch("type")
        sha = object.fetch("sha")
        return sha if type == "commit" && sha.match?(/\A[0-9a-f]{40}\z/)
        raise PolicyError, "Release tag resolves to unsupported object type: #{type}" if type != "tag"

        object = api_json("/repos/#{repository}/git/tags/#{sha}").fetch("object")
      end

      raise PolicyError, "Release tag annotation chain is too deep: #{repository}@#{tag}"
    rescue KeyError, JSON::ParserError => e
      raise PolicyError, "Malformed GitHub tag response: #{e.message}"
    end

    def download_asset(repository, asset_id, destination)
      command = [
        "gh", "api", "--method", "GET",
        "-H", "Accept: application/octet-stream",
        "/repos/#{repository}/releases/assets/#{asset_id}"
      ]
      stderr_text = nil
      status = nil
      File.open(destination, "wb") do |file|
        Open3.popen3(*command) do |stdin, stdout, stderr, wait_thread|
          stdin.close
          stderr_reader = Thread.new { stderr.read }
          IO.copy_stream(stdout, file)
          stderr_text = stderr_reader.value
          status = wait_thread.value
        end
      end
      return if status.success?

      raise PolicyError, "GitHub asset download failed: #{stderr_text.strip}"
    end

    def verify_attestation(path, repository, source_digest)
      workflow = "github.com/#{repository}/.github/workflows/release.yml"
      run!(
        "gh", "attestation", "verify", path,
        "--repo", repository,
        "--signer-workflow", workflow,
        "--source-ref", "refs/heads/main",
        "--source-digest", source_digest,
        "--deny-self-hosted-runners"
      )
    end

    private

    def api_json(endpoint)
      JSON.parse(run!("gh", "api", "--method", "GET", endpoint))
    end

    def run!(*command)
      stdout, stderr, status = Open3.capture3(*command)
      return stdout if status.success?

      raise PolicyError, "Command failed (#{command.first(3).join(" ")}): #{stderr.strip}"
    end

    def encode_path_component(value)
      URI.encode_www_form_component(value)
    end
  end

  # Checks release metadata, downloaded bytes, and build provenance for every selector.
  class ReleaseVerifier
    def initialize(client: GitHubClient.new)
      @client = client
    end

    def verify!(plan)
      repository = plan.fetch("repository")
      tag = plan.fetch("tag")
      release = @client.release(repository, tag)
      assets = validate_release!(plan, release)
      release_commit = @client.resolve_tag_commit(repository, tag)

      Dir.mktmpdir("publisher-cask-") do |directory|
        assets.each_with_index do |asset, index|
          path = File.join(directory, "#{index}-#{asset.fetch("name")}")
          @client.download_asset(repository, asset.fetch("id"), path)
          validate_download!(asset, path)
          @client.verify_attestation(path, repository, release_commit)
        end
      end

      {
        "release_commit" => release_commit,
        "artifacts"      => assets.map { |asset| asset.slice("selector", "name", "sha256") },
      }
    end

    def validate_release!(plan, release)
      valid_release = release.is_a?(Hash) && release["tag_name"] == plan.fetch("tag")
      unless valid_release
        raise PolicyError, "GitHub release tag does not match the cask version"
      end
      if release["draft"] != false || release["prerelease"] != false || release["published_at"].to_s.empty?
        raise PolicyError, "Cask assets must come from a published, stable GitHub release"
      end
      raise PolicyError, "GitHub release assets are missing" unless release["assets"].is_a?(Array)

      plan.fetch("artifacts").map do |expected|
        matches = release.fetch("assets").select { |asset| asset["name"] == expected.fetch("name") }
        raise PolicyError, "Release must contain exactly one #{expected.fetch("name")}" if matches.length != 1

        validate_asset!(plan, expected, matches.first)
      end
    end

    private

    def validate_asset!(plan, expected, asset)
      expected_digest = "sha256:#{expected.fetch("sha256")}"
      if asset["digest"] != expected_digest
        raise PolicyError,
              "Release digest does not match #{expected.fetch("selector")}"
      end
      valid_id = asset["id"].is_a?(Integer) && asset["id"].positive?
      unless valid_id
        raise PolicyError,
              "Release asset ID is invalid: #{expected.fetch("name")}"
      end
      valid_size = asset["size"].is_a?(Integer) && asset["size"].positive?
      unless valid_size
        raise PolicyError,
              "Release asset size is invalid: #{expected.fetch("name")}"
      end

      expected_url = "https://github.com/#{plan.fetch("repository")}/releases/download/#{plan.fetch("tag")}/#{expected.fetch("name")}"
      if asset["browser_download_url"] != expected_url
        raise PolicyError, "Release download URL does not match #{expected.fetch("name")}"
      end

      expected.merge("id" => asset.fetch("id"), "size" => asset.fetch("size"))
    end

    def validate_download!(asset, path)
      if File.size(path) != asset.fetch("size")
        raise PolicyError, "Downloaded size does not match #{asset.fetch("name")}"
      end
      return if Digest::SHA256.file(path).hexdigest == asset.fetch("sha256")

      raise PolicyError, "Downloaded checksum does not match #{asset.fetch("selector")}"
    end
  end

  module_function

  def verify_pr!(root: repository_root, env: ENV, client: GitHubClient.new)
    metadata = %w[BASE_REF BASE_SHA HEAD_REF HEAD_REPOSITORY HEAD_SHA PR_AUTHOR_ID PR_TITLE REPOSITORY].to_h do |name|
      [name, env.fetch(name) { raise PolicyError, "Missing environment variable: #{name}" }]
    end

    if metadata.fetch("PR_AUTHOR_ID") != BOT_USER_ID
      raise PolicyError, "starhaven-bot may not update a pull request authored by another identity"
    end
    if metadata.fetch("REPOSITORY") != TAP_REPOSITORY ||
       metadata.fetch("HEAD_REPOSITORY") != TAP_REPOSITORY ||
       metadata.fetch("BASE_REF") != "main"
      raise PolicyError, "starhaven-bot pull requests must use a same-repository branch targeting main"
    end

    base_sha = resolve_commit(root, metadata.fetch("BASE_SHA"))
    head_sha = resolve_commit(root, metadata.fetch("HEAD_SHA"))
    status, path = exactly_one_change(root, base_sha, head_sha)
    path_match = path&.match(CASK_PATH_PATTERN)
    valid_change = status == "M" && path_match
    unless valid_change
      raise PolicyError, "Tap publisher pull requests may modify exactly one existing cask definition"
    end

    token = path_match[1]
    version = title_version(metadata.fetch("PR_TITLE"), token)
    expected_branch = "bump-#{token}-#{version}"
    if metadata.fetch("HEAD_REF") != expected_branch
      raise PolicyError, "Tap publisher branch, title, and cask path do not agree"
    end

    plan = build_plan(root: root, base_ref: base_sha, head_ref: head_sha, token: token, expected_version: version)
    result = ReleaseVerifier.new(client: client).verify!(plan)
    { "plan" => plan, "verification" => result }
  end

  def build_plan(root:, base_ref:, head_ref:, token:, expected_version:)
    validate_token!(token)
    raise PolicyError, "Publisher cask is not in the tap inventory: #{token}" unless PRODUCTS.key?(token)

    validate_version!(expected_version)

    base_sha = resolve_commit(root, base_ref)
    head_sha = resolve_commit(root, head_ref)
    base_source = SourceParser.new(read_cask(root, base_sha, token), token).parse
    head_source = SourceParser.new(read_cask(root, head_sha, token), token).parse

    if base_source.fetch(:normalized) != head_source.fetch(:normalized)
      raise PolicyError, "Publisher cask updates may change only version and sha256 values"
    end
    if head_source.fetch(:version) != expected_version
      raise PolicyError, "Publisher cask version does not match the pull request title"
    end

    validate_version!(base_source.fetch(:version))
    if Gem::Version.new(head_source.fetch(:version)) <= Gem::Version.new(base_source.fetch(:version))
      raise PolicyError, "Publisher cask version must advance monotonically"
    end
    if base_source.fetch(:repository) != head_source.fetch(:repository)
      raise PolicyError, "Publisher cask repository changed"
    end

    {
      "schema"     => 1,
      "cask"       => token,
      "repository" => head_source.fetch(:repository),
      "version"    => head_source.fetch(:version),
      "tag"        => head_source.fetch(:tag),
      "artifacts"  => head_source.fetch(:artifacts),
    }
  end

  def repository_root
    File.expand_path("..", __dir__)
  end

  def resolve_commit(root, ref)
    output = git(root, "rev-parse", "--verify", "#{ref}^{commit}").strip
    raise PolicyError, "Git reference did not resolve to a commit: #{ref}" unless output.match?(/\A[0-9a-f]{40}\z/)

    output
  end

  def read_cask(root, commit, token)
    path = "Casks/#{token}.rb"
    tree_entry = git(root, "ls-tree", "-z", commit, "--", path)
    match = tree_entry.match(/\A(?<mode>\d+) blob [0-9a-f]{40}\t#{Regexp.escape(path)}\0\z/)
    valid_file = match && match[:mode] == "100644"
    unless valid_file
      raise PolicyError, "Publisher cask must be a regular non-executable file: #{token}"
    end

    size = Integer(git(root, "cat-file", "-s", "#{commit}:#{path}").strip, 10)
    raise PolicyError, "Publisher cask is unexpectedly large: #{token}" if size > MAX_CASK_BYTES

    git(root, "show", "#{commit}:#{path}")
  rescue ArgumentError
    raise PolicyError, "Publisher cask size is invalid: #{token}"
  end

  def exactly_one_change(root, base_sha, head_sha)
    fields = git(root, "diff", "--name-status", "--no-renames", "-z", "#{base_sha}...#{head_sha}").split("\0", -1)
    fields.pop if fields.last == ""
    return [nil, nil] if fields.length != 2

    fields
  end

  def title_version(title, token)
    prefixes = ["#{token} ", "chore(cask): update #{token} to "]
    prefix = prefixes.find { |candidate| title.start_with?(candidate) }
    raise PolicyError, "Tap publisher branch, title, and cask path do not agree" unless prefix

    version = title.delete_prefix(prefix)
    validate_version!(version)
    version
  end

  def validate_token!(token)
    raise PolicyError, "Invalid cask token: #{token}" unless token.match?(TOKEN_PATTERN)
  end

  def validate_version!(version)
    return if version.match?(VERSION_PATTERN) && Gem::Version.correct?(version)

    raise PolicyError, "Invalid publisher cask version: #{version}"
  end

  def git(root, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", root, *arguments)
    return stdout if status.success?

    raise PolicyError, "Git command failed (#{arguments.first}): #{stderr.strip}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    result = PublisherCaskPolicy.verify_pr!
    puts JSON.pretty_generate(result)
  rescue PublisherCaskPolicy::PolicyError, KeyError, JSON::ParserError => e
    warn "publisher_cask_policy: #{e.message}"
    exit 1
  end
end
