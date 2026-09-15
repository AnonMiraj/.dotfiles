{
  lib,
  buildNpmPackage,
  nodejs_22,
  cashflowSrc,
}:

buildNpmPackage {
  pname = "cashflow";
  version = "unstable-${cashflowSrc.shortRev or "unknown"}";

  src = cashflowSrc;
  nodejs = nodejs_22;
  npmDepsHash = "sha256-0G9v3BrKbgvVBaUrTk+FCX0qHDneEOTWwjj0HSA+SCU=";
  npmBuildScript = "build";

  # The stock npmInstallHook ships the `npm pack` file list, which drops dist/
  # because upstream .gitignore excludes it. Install the built tree explicitly.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/cashflow
    cp -r dist server shared package.json $out/lib/cashflow/
    npm prune --omit=dev --no-save
    cp -r node_modules $out/lib/cashflow/node_modules

    runHook postInstall
  '';

  meta = {
    description = "Browser property game server (Cash Flow)";
    homepage = "https://cashflow.almiraj.xyz";
    mainProgram = "cashflow";
    platforms = lib.platforms.linux;
  };
}
