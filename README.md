# Minesweeper
BlitzMax port of [**Minesweeper-Switch**](https://github.com/rincew1nd/Minesweeper-Switch) by [rincew1nd](https://github.com/rincew1nd)



Built as a proof-of-concept for BlitzMax NG's new NX support.



## Features

Also works on Desktop platforms ;-)



## TODO

* Implement the text stuff
* Fix start/end game issues.



## Installing devkitPro

The NX platform requires an installation of devkitPro homebrew for the Switch, and SDL2.

Official information about setting up can be found here : https://devkitpro.org/wiki/Getting_Started 

### Windows

Get the latest devkitpro installer : https://sourceforge.net/projects/devkitpro/

This installs MSYS, pacman and the toolchains for building NX apps.

### Linux and macOS

```pacman``` can be installed via github : https://github.com/devkitPro/pacman/releases

A Linux .deb file and macOS .pkg are provided.

## Using pacman to install dependencies

```pacman``` is the preferred package manager used by the homebrew folks to keep devkitPro and its dependencies updated.

If it isn't already installed, we need to install the ```switch-dev``` package and SDL2 library using pacman.

To list all the available packages, use : ```pacman -Sl```

Packages which are already installed have ```[installed]``` next to it in the list.

You will see that the SDL2 package is called ```switch-sdl2```.

To install a package, run : ```pacman -S <name-of-package>```



## Configure and Build

Once devkitPro is installed, you need to tell BlitzMax where to find it. You can do this by adding the ```nx.devkitpro``` option to ```custom.bmk``` in the BlitzMax bin folder :

```addoption nx.devkitpro "<path to>\devkitPro"```

You may want to get the latest MaxIDE, which supports compiling of NX projects via the menus.

Otherwise, you can use the following options on the commandline for ```bmk``` to select the target platform and architecture : ```-g arm64 -l nx```



## Executing

The NX platform has been tested using the ryujinx emulater : https://ryujinx.org/#/

From the commandline, you can run ```<path to ryujinx>/publish/Ryujinx minesweeper.nro```

