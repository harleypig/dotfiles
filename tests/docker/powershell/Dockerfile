# The pinned image for tests/shell/test_integration_powershell.bats.
#
# Never built: the test reads the image reference off the FROM line below and
# runs that stock image directly. This file exists so Dependabot's docker
# ecosystem can see the pin and bump it. Keep exactly one FROM line, pinned
# by tag and digest; the test fails on anything else.
#
# The PowerShell team's own mcr.microsoft.com/powershell images are
# deprecated and frozen (latest is pwsh 7.4.2); Microsoft now ships pwsh in
# the .NET SDK image. The -noble tags carry pwsh (LTS) on Ubuntu 24.04.
#
# Microsoft publishes this image only on mcr.microsoft.com, which the
# global hadolint baseline does not list as a trusted registry.
# hadolint ignore=DL3026
FROM mcr.microsoft.com/dotnet/sdk:10.0.403-noble@sha256:de4fe90a98845d75910b9769662465c84de1a934665c431279d1382b2bddc02b
