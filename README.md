# nurse

Nurse is a simple environment status script (sometimes called diagnostics script) written in bash. The purpose is to output a readable status report for support teams.

> [!important]
>
> 1. Always, always verify the files you are downloading and running **BEFORE** running them!
> 2. To run `nurse`, curlbash [run.sh](run.sh), not `nurse.sh`! This way the checksum is verified against this (<https://github.com/hxii/nurse>) repository prior to execution.
> 3. This script was intended to be used internally, so certain assumptions (e.g. platform, paths) are made.

## Usage

Run `curl -fsSL https://github.com/hxii/nurse/releases/latest/download/run.sh | bash`
