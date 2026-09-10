"""Project only the pipeline credential from the existing Docker env file."""

import os
from pathlib import Path


def pipeline_environment(source: str) -> str:
    # Docker env files preserve values verbatim; do not shell-evaluate secrets.
    values = {}
    for raw in source.splitlines():
        line = raw.lstrip()
        if not line or line.startswith("#"):
            continue
        name, separator, value = line.partition("=")
        if separator:
            values[name] = value
    secret = values.get("AI__PipelineApi__SharedSecret", "")
    if not secret.strip():
        raise ValueError("AI__PipelineApi__SharedSecret is missing from bosla-env")
    return f"PIPELINE_SHARED_SECRET={secret}\n"


if __name__ == "__main__":
    content = pipeline_environment(Path("/run/secrets/bosla-env").read_text())
    target = Path("/run/bosla-pipeline/environment")
    os.umask(0o077)
    temporary = target.with_suffix(".tmp")
    temporary.write_text(content)
    temporary.chmod(0o600)
    temporary.replace(target)
