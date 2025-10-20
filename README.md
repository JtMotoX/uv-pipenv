# uv-pipenv

This adds pipenv/pipfile support with only 'uv'. With this, you no longer need to install and configure python on your host. Simply [install uv](https://docs.astral.sh/uv/getting-started/installation/), clone this repo, and execute `./uv-pipenv.sh --help`.

### Example:
```bash
cd /directory/that/contains/your/pipfile
./uv-pipenv.sh --python 3.11 --pipenv 2023.7.23 --update-lock
```
