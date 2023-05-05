# development-environment
Docker image that can be used as an environment for modern software development.

Supports multiple editors and programming languages.

# Supported IDEs and editors

## Visual Studio Code
For VS Code, this image is intened to be used with the DevContainers plugin.  
Example configuration:
```json
{
	"name": "Development Environment",
	"image": "ghcr.io/proxyprotocol/development-environment:0.0.1-ubuntu"
}
```

## Neovim
This image includes neovim 0.9 with some additional plugins that help with the development process. Based mostly on https://github.com/ThePrimeagen/init.lua.

Custom configurations and/or plugins can be managed via volumes.

# Supported languages 
## C++
For C++ development, this image contains: 
- GCC 12
- LLVM/Clang 16
- cmake 3.26.3
- Conan 2.0.4
- Nina 1.11.1

## Python 
Version: 3.10

# How to extend / customize
Since this is just a docker image anyone can extend its functionalities by creating new image that is based on this one.
