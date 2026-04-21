{pkgs, ...}: let
  version = "0.0.55";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/opencode-ai/opencode/releases/download/v${version}/opencode-linux-x86_64.tar.gz";
      hash = "sha256-fx9BID55IK7Ejz4iFtM06c6MbQp7EHzrdY/vpNTJgCU=";
    };
    "aarch64-linux" = {
      url = "https://github.com/opencode-ai/opencode/releases/download/v${version}/opencode-linux-arm64.tar.gz";
      hash = "sha256-Uw6xNv38nq3vlqoiULvbkhDp98wb1Pcz0zLKndYdIuA=";
    };
  };

  opencode-unwrapped = pkgs.stdenv.mkDerivation {
    pname = "opencode-unwrapped";
    inherit version;
    src = pkgs.fetchurl sources.${pkgs.system};
    sourceRoot = ".";
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      install -Dm755 opencode $out/bin/opencode
    '';
  };

  # Pre-built config template with a placeholder for the API key.
  # The wrapper script below substitutes SCW_SECRET_KEY at runtime,
  # since the key is not available at build time.
  opencodeConfig = pkgs.writeText "opencode.json" (builtins.toJSON {
    providers = {
      anthropic = {disabled = true;};
      openai = {disabled = true;};
      groq = {disabled = true;};
      openrouter = {disabled = true;};
      xai = {disabled = true;};
      copilot = {disabled = true;};
      bedrock = {disabled = true;};
      azure = {disabled = true;};
      vertexai = {disabled = true;};
      gemini = {disabled = true;};
      local = {apiKey = "@SCW_SECRET_KEY@";};
    };
  });

  opencode = pkgs.writeShellScriptBin "opencode" ''
    if [ -n "$SCW_SECRET_KEY" ]; then
      ${pkgs.gnused}/bin/sed "s|@SCW_SECRET_KEY@|$SCW_SECRET_KEY|" ${opencodeConfig} > "$HOME/.opencode.json"
    fi
    exec ${opencode-unwrapped}/bin/opencode "$@"
  '';
in {
  environment.systemPackages = [
    opencode
  ];

  environment.variables = {
    # Tell Open Code's local provider to use Scaleway's OpenAI-compatible API
    LOCAL_ENDPOINT = "https://api.scaleway.ai/v1";
  };
}
