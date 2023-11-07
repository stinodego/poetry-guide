# Poetry guide

This repository contains some pointers and resources for setting up your own projects to use [Poetry](https://python-poetry.org/).

Poetry is an amazing, modern tool for developing Python packages. It helps you fully lock down all your dependencies and easily manage version adding/removing/updating packages. In my opinion, it is a necessary tool to run Python in production environments.

This guide is a handy step-by-step reference for setting up your project when you're first getting acquainted with Poetry. It is NOT meant to be a comprehensive usage guide. Please refer to the [excellent documentation](https://python-poetry.org/docs/) for this.

## Table of contents
- [Installation](#installation)
- [Project setup](#project-setup)
- [Project management](#project-management)
- [Using Poetry with Docker](#using-poetry-with-docker)
- [Using Poetry with GitHub Actions](#using-poetry-with-github-actions)
- [Using Poetry with Databricks](#using-poetry-with-databricks)
- [F.A.Q.](#faq)

## Installation

Before you get started, it is important to note that Poetry does not only help manage your dependencies, it also manages virtual environments for your projects. It works perfectly in conjunction with [pyenv](https://github.com/pyenv/pyenv), which manages your base Python version. The subsection below will explain how to set this up.

**If you have conda installed on your system, the steps below will likely NOT work!** Please skip to the [conda](#conda-and-poetry) subsection for instructions on using Poetry in conjunction with conda. For the rest of the guide, I will assume you are using the pyenv/poetry setup.

### pyenv and Poetry

pyenv is a great tool for managing different base Python versions. This comes in handy when you need different versions for different projects. For example, one project might run on Databricks, and you'll want to emulate the Databricks runtime using Python 3.8.10. On another project, you might want to use the latest Python version. pyenv helps you do this.

Start by installing pyenv. For macOS, I recommend [using Homebrew](https://github.com/pyenv/pyenv#homebrew-in-macos). For Linux, I recommend [using the installer](https://github.com/pyenv/pyenv-installer#install):

```bash
curl https://pyenv.run | bash
```

Once pyenv is installed, install the Python version of your choice. You may have to install some dependencies to get this to work.

```bash
pyenv install 3.10.5
```

Now you are ready to install Poetry! First, make sure your system Python is selected. This makes sure Poetry remains available even if you decide to remove a specific version of Python.

```bash
pyenv global system
```

Then, [install Poetry](https://python-poetry.org/docs/master/#installation):

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

That's it! You should be ready to get started setting up your project.

Before you do, I recommend configuring Poetry to create its virtual environments [in your project directory](https://python-poetry.org/docs/configuration/#virtualenvsin-project). This step is completely optional.

```bash
poetry config virtualenvs.in-project true
```

### conda and Poetry

If you prefer use conda for managing your virtual environments, that is perfectly fine. When starting a new project, create a new conda environment with your desired base Python version. Activate the environment, and install poetry using pip:

```bash
pip install poetry
```

This will make sure poetry installs and resolves dependencies in your active conda environment. That's all there is to it!


## Project setup

This repository includes a minimal Python package. The package is managed using Poetry. Below are the steps I took to set this up, with explanations. Feel free to reproduce this in a fresh folder, or try setting this up for your existing project.

### 1. Navigate to your project directory

Poetry always interacts with the current working directory, even if you currently have a different virtual environment active. It will interact with the `pyproject.toml` and `poetry.lock` files in the current working directory.

### 2. Set your base Python version

Choose the base Python version for your project using pyenv.

```bash
pyenv global 3.10.5
```

### 3. Initialize your package

Use Poetry's `init` command to interactively specify your package information. Don't worry, you can manually change this later. For now, skip the interactive definition of your desired dependencies.

```bash
poetry init
```

This will generate a `pyproject.toml` file in your directory (or append to the file if it already exist). This file is where Poetry collects all information about your package.

### 4. Specify your package

It is [good practice](https://blog.ionelmc.ro/2014/05/25/python-packaging/#the-structure) to use a `src` folder that contains your package. You will have to tell Poetry that it can find your package there by adding the following lines to the `pyproject.toml` file:


```toml
packages = [
    { include = "mypackage", from = "src" }
]
```

If your package lives on the top-level, you can skip this step.

### 5. Create your virtual environment

We have to tell Poetry to use the Python version we enabled in [step 2](#2-set-your-base-python-version):

```bash
poetry env use $(pyenv which python)
```

This creates a virtual environment. You can find the location of the environment by typing `poetry env info`. It's a good idea to tell your IDE to use this environment; both VSCode and Pycharm have built-in support for Poetry environments.

### 6. Add your dependencies

Let's add some dependencies. **Do not add these manually to the `pyproject.toml` file!** Instead, use Poetry's CLI:

```bash
poetry add polars
```

At this point, the `poetry.lock` file will be created. This file tracks the fully resolved and locked dependencies for your project. It is updated anytime you add, remove, or update a dependency using the Poetry CLI.

Let's also add a testing dependency in a separate [dependency group](https://python-poetry.org/docs/master/managing-dependencies/):

```bash
poetry add pytest --group test
```

Dependency groups have a special status. You can easily choose to omit them when installing your project in a Docker container, for example.

### 7. Add a CLI script

You can make your application available through a CLI script by adding a section to the `pyproject.toml` file and pointing to a function in your package. Not required by any means, but I'd say it's a good way to set up your application.

```toml
[tool.poetry.scripts]
mycli = 'mypackage.main:main'
```

### 8. Install your package

Our virtual environment contains the package dependencies, but not yet our own package. Time to install it:

```bash
poetry install
```

### 9. Activate your virtual environment

If your IDE hasn't yet taken care of this, you can activate your virtual environment using the Poetry CLI:

```bash
poetry shell
```

That's it! You have your package and matching virtual environment all set up.


## Project management

Here's some situations you may run into while developing or maintaining your application, and how Poetry can help.

### "I want to do a routine update of my dependencies"

Poetry provides an `update` command that updates all your dependencies to the newest, non-breaking versions. It uses semantic versioning to determine which versions are safe to upgrade to.

```bash
poetry update
```

### "I want to update a package to a new major version"

New major versions contain updates that are possibly not backwards compatible. If you want to upgrade, use the `@latest` tag like so:

```bash
poetry add polars@latest
```

### "There is a security issue with one of my dependencies"

GitHub's dependabot supports Poetry, and you can configure it to automatically open pull requests for updating your `poetry.lock` / `pyproject.toml`. Super simple!

Running `poetry update` manually should also take care of this issue, but this will update multiple dependencies.

### "I want to update my local environment after my teammate added a new dependency."

Make sure your local directory contains the latest lockfile, and simply run:

```bash
poetry install --sync
```


## Using Poetry with Docker

Applications should be distributed as container images. There are two ways you can use Poetry to make sure your application is available in the container and installed with fully locked down dependencies:
* Use Poetry in your container to install your dependencies and then your package.
* Prepare a `requirements.txt` beforehand and use `pip` to install these dependencies and then your package in your container.

The `docker/` folder contains examples of both approaches.

### Using Poetry in your container

My preferred way is to install Poetry in the container and use it to install your package. I'd argue it is simpler and more intuitive. I included two example Dockerfiles with this approach:
* A minimal example that includes the bare necessities, to showcase the concepts.
* An optimized example that includes some improvements on layer caching and security. You should be able to use this Dockerfile for your own project with minimal adjustments.

Try building and running the Dockerfile to see that it works:

```bash
docker build -t mypackage:optimized -f docker/Dockerfile.optimized .
docker run --rm mypackage:optimized
```

### Container without Poetry

If you do not want to install poetry in your Docker container, you can avoid this by exporting a `requirements.txt` beforehand. The Poetry CLI supports this:

```bash
poetry export > requirements.txt
```

As you can see, this file does not include any development dependencies. You can also use `pip` to install a poetry package, as showcased in the Dockerfile. Try building and running this version:

```bash
docker build -t mypackage:nopoetry -f docker/Dockerfile.nopoetry .
docker run --rm mypackage:nopoetry
```


## Using Poetry with GitHub Actions

You may want to utilize Poetry to set up a testing environment on your GitHub runner. There is GitHub Action available for installing Poetry on your runner: [snok/install-poetry](https://github.com/snok/install-poetry). The GitHub page includes a sample test workflow. I have also included that same workflow in this repository for reference.

A more ideal setup would be to run your tests in a Docker container. You can add a second stage to your Dockerfile to install the development dependencies and then use this image to run your tests. I will add an example workflow for this once I have tested this approach fully.


## Using Poetry with Databricks

If you use your application to run Databricks workloads, it is recommended to use [Databricks Container Services](https://docs.databricks.com/clusters/custom-containers.html). This allows you to specify a custom Docker container for your workloads.

You can set up the Docker container similarly to the Dockerfiles in this repository, using a Databricks base image instead. There are some caveats. Refer to my Databricks Container Services guide (coming soon) for more in-depth information.


## F.A.Q.

Feel free to ask a question as a GitHub issue, and I might add it here.

### Can I distribute my project as a wheel?

Yes! The Poetry CLI has a `build` command that allows you to build a wheel. Note that it will not use your locked dependencies. Rather, the 'open' dependencies specified in the `pyproject.toml` will be used.

```bash
poetry build --format wheel
```

### What if my teammates really don't want to use Poetry?

Transitioning from a `setup.py` setup to a `pyproject.toml` setup can be quite seamless. Poetry and `pyproject.toml` support all the functionality of `setup.py`. For example, `pip install -e .` still works.

The only caveat is that `pip` does not recognize Poetry's special development dependencies. If you want to `pip install -e .[dev]`, you will have to specify your development dependencies as [extras](https://python-poetry.org/docs/pyproject/#extras):

```toml
[tool.poetry.extras]
dev = ["pytest"]
```

And as showcased, your Dockerfile can remain Poetry-free. So full backward compatibility is guaranteed. So your less tech-savvy teammates can stick to their old ways, while you move the project into the future!
