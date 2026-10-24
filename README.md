# template

template repo is a generic starter repo for vic20/commodore development

This repository contains the current version of the BASIC source and an automated build workflow that generates a `.prg` file whenever a `.bas` file is merged through a pull request.

## features

- list game features here


## how to play
game instructions here

## screenshots
![gameplay](screenshots/gameplay1.png)
![merge](screenshots/gameplay2.png)
![gameover](screenshots/gameover.png)

## compatibility
list compatibility and hardware requirements

## repository layout

```
src/
  template.bas        main BASIC source file, rename for your project

prgs/
  (auto-generated .prg files created by the GitHub Action)

tools/
  petcat           linux petcat executable used by CI
  petcat.exe       windows petcat executable for local development
  c1541            linux c1541 executable used by CI for generating disk images
  c1541.exe        windows c1541 executable used for generating disk images

buildtools/
  build-and-run.ps1  local build: petcat the current .bas, then autostart it in xvic
  screenshot.ps1     save the running xvic screen to screenshots/temp/ (gitignored)
  tasks.vs.json      Visual Studio task (copy to .vs/tasks.vs.json)
  tasks.json         VS Code task (copy to .vscode/tasks.json)

docs/
  design.md        optional notes about game logic or memory usage
  changelog.md     version history

.github/
  workflows/
    build-prg.yml  automatic build on PR merge
```

## building

The `.prg` file is generated using `petcat`. The repository includes both Linux and Windows versions of petcat in the `tools` folder.

To build manually:

```
petcat -w2 -o template[.prg] src/template.bas
```

This produces a PRG that can be loaded on a VIC-20 or in VICE.

### build and run from the IDE

`buildtools/build-and-run.ps1` builds the open `.bas` file into `prgs/` and autostarts it in xvic. If xvic is already running with its remote monitor on port 6510, the program is sent to that window; otherwise a new xvic is started with `-remotemonitor`. `petcat.exe` and `xvic.exe` must be on your `PATH`.

The IDE config folders are gitignored, so copy the task file into place once:

- Visual Studio (Open Folder): copy `buildtools/tasks.vs.json` to `.vs/tasks.vs.json`, then Build with a `.bas` file active.
- VS Code: copy `buildtools/tasks.json` to `.vscode/tasks.json`, then run the default build task.

## running

### run in VICE

```
xvic -memory unexpanded template.prg
```

or load it from the BASIC prompt:

```
load "template.prg",8
run
```

### run on real hardware

Copy the PRG to a disk image or transfer it using your preferred method (SD2IEC, Pi1541, etc.). The game requires no RAM expansion.

## development notes

Additional technical notes, PETSCII layout sketches, and memory usage details can be found in the `docs` folder. These files are optional and may grow as the project evolves.

## automatic build (work in progress)

When a pull request containing changes to any `.bas` file is merged, the GitHub Action in `.github/workflows/build-prg.yml` automatically:

- copies the repo’s `tools/petcat` executable into the action runner  
- runs `petcat` to generate the `.prg` file  
- writes the resulting `.prg` file into the `prgs` folder  
- commits the generated file back to the main branch  

This keeps the PRG output synchronized with the BASIC source without installing the full VICE package.

## license

This project is released under the MIT License. See the `LICENSE` file for details.
