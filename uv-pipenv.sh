#!/bin/sh

set -e

# Help function
show_help() {
	cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build a Python virtual environment using uv and pipenv.

OPTIONS:
    -h, --help              Show this help message and exit
    -u, --update-lock       Update Pipfile.lock without prompting
    -p, --python VERSION    Python version to use (default: 3.10)
    -v, --pipenv VERSION    Pipenv version to use (default: 2022.7.24)
    --pypi-user-file FILE   Path to PYPI user file (default: ../PYPI_USER.txt)
    --pypi-token-file FILE  Path to PYPI token file (default: ../PYPI_TOKEN.txt)

ENVIRONMENT VARIABLES:
    PYTHON_VERSION          Python version (overridden by -p)
    PIPENV_VER              Pipenv version (overridden by -v)
    PYPI_USER_FILE          Path to PYPI user file (overridden by --pypi-user-file)
    PYPI_TOKEN_FILE         Path to PYPI token file (overridden by --pypi-token-file)
    UPDATE_LOCK             Set to 'true' or 'false' to skip prompt

EXAMPLES:
    $(basename "$0")                           # Interactive mode
    $(basename "$0") -u                        # Update lock file without prompt
    $(basename "$0") -p 3.11 -v 2023.10.24     # Use specific versions

EOF
}

# Parse command line arguments
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			show_help
			exit 0
			;;
		-u|--update-lock)
			UPDATE_LOCK=true
			shift
			;;
		-p|--python)
			if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
				PYTHON_VERSION="$2"
				shift 2
			else
				echo "Error: --python requires a version argument" >&2
				exit 1
			fi
			;;
		-v|--pipenv)
			if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
				PIPENV_VER="$2"
				shift 2
			else
				echo "Error: --pipenv requires a version argument" >&2
				exit 1
			fi
			;;
		--pypi-user-file)
			if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
				PYPI_USER_FILE="$2"
				shift 2
			else
				echo "Error: --pypi-user-file requires a file path argument" >&2
				exit 1
			fi
			;;
		--pypi-token-file)
			if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
				PYPI_TOKEN_FILE="$2"
				shift 2
			else
				echo "Error: --pypi-token-file requires a file path argument" >&2
				exit 1
			fi
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			echo "Run '$(basename "$0") --help' for usage information." >&2
			exit 1
			;;
	esac
done

# MAKE SURE PIPFILE EXISTS
if [ ! -f Pipfile ]; then
	echo "Pipfile not found! Are you in the project root?"
	exit 1
fi

# PROMPT USER Y/N IF LOCK FILE SHOULD BE UPDATED
if [ ! -f Pipfile.lock ]; then
	echo "No Pipfile.lock found, proceeding to create one."
	UPDATE_LOCK=true
elif [ "$UPDATE_LOCK" = "true" ]; then
	echo "UPDATE_LOCK is set to true, proceeding to update Pipfile.lock."
elif [ "$UPDATE_LOCK" = "false" ]; then
	echo "UPDATE_LOCK is set to false, skipping Pipfile.lock update."
fi

# SETUP PYPI CREDENTIALS
PYPI_USER_FILE="${PYPI_USER_FILE:-../PYPI_USER.txt}"
PYPI_TOKEN_FILE="${PYPI_TOKEN_FILE:-../PYPI_TOKEN.txt}"
export PYPI_USER=$(cat "${PYPI_USER_FILE}")
export PYPI_TOKEN=$(cat "${PYPI_TOKEN_FILE}")

# BUILD A TEMPORARY VENV JUST FOR RUNNING PIPENV
uv venv --python ${PYTHON_VERSION:-3.10} /tmp/.venv-build --clear
. /tmp/.venv-build/bin/activate
uv pip install pipenv==${PIPENV_VER:-2022.7.24}
uv pip install --upgrade certifi
export REQUESTS_CA_BUNDLE=$(python -c "import certifi; print(certifi.where())")

# CONFIGURE PIPENV TO CREATE THE VENV IN THE PROJECT FOLDER
export PIPENV_VENV_IN_PROJECT=true
export PIPENV_IGNORE_VIRTUALENVS=1

# BUILD THE PROJECT VENV
pipenv --python ${PYTHON_VERSION:-3.10}
if [ "$UPDATE_LOCK" = true ]; then
	pipenv lock
fi
pipenv sync --sequential

# SHOW INSTALLED PACKAGES
. .venv/bin/activate
rm -rf /tmp/.venv-build
echo "--- Installed package tree: ---"
uv pip tree

# INFORM THAT BUILD IS COMPLETE AND HOW TO ACTIVATE
echo ""
echo "Build complete! To activate the new virtual environment, run:"
echo "  source .venv/bin/activate"
