# VGCTourHelper

Are you organizing a VGC tournament you would like to stream but you haven't got any fancy OTS graphic for the streamed matches or any pairings scene? Or maybe you just want to automatically post pairings online for your players? You are in the right place, VGCTourHelper is built exactly with those purposes in mind!
VGCTourHelper is a tool aimed to help you in running your tournament while avoiding any unnecessary complicated installation or setup. It is designed to work with TOM (Tournament Operation Manager) outputs and with the standard team export of [Pokémon Showdown](https://play.pokemonshowdown.com) (as well as [PokePaste](https://poekpast.es) and all of its forks).

## Compiling and installing

This application supports all Delphi versions from XE8 onwards, it should always compile with no warnings or hints.
Since this project uses FireMonkey components it can be built for both Windows and macOS. We are planning to publish compiled releases under [MilanoVGC](https://github.com/MilanoVGC).
The only external library that this application relies on is [OpenSSL](https://github.com/openssl/openssl): on Windows you must download/build ssleay32.dll and libeay32.dll and place them on the same path as VGCTourHelper, on macOS OpenSSL should already be installed by default.
With that out of the way, just run the executable and you are done!

## Running

Here is the basic flow of the application: just launch it and follow these steps
1. *(only on the very first run, when streaming)* link your OBS scene to the [output files](#Outputs)
2. import a TDF file (TOM output) to initialize the tournament
3. import a CSV file containing the list of Player IDs and Pastes
4. start the tournament
5. *(when streaming)* select a match to be streamed
6. add/update/replace the TDF file as the tournament progresses

And that's it, more details can be found on the following sections.

## Inputs and data files

VGCTourHelper runs on three kinds of data files
1. TOM output file (*.tdf)
	- can be the main tournament file that the TOM updates on every progression of the tournament or the "side" file that TOM can output for each round phase (*_begin and *_end)
	- when working automatically it updates the tournament whenever the main file is updated or when a new TOM output file is added to the folder of the first selected one
	- if not working automatically each updated or new file has to be selected and the tournament has to be manually updated by clicking a button
2. Paste file (*.csv)
	- must include two columns: "PlayerId" and "Paste" (names are changeable, see [configuration](#Config)), separated by ";"
	- the column "Paste" can contain either a URL to PokePaste (or one of its forks) or the entire team in the export-to-text format
	- OTS and CTS formats are equally accepted - reserved informations (such as natures) will never be on display
3. Data files (*.csv)
	- internal resources for VGCTourHelper and are usually shipped with the application itself (you can find them under [this path](./Home/Resources/Data))
	- should never need to be updated or edited
	- as all of the CSV files, they depend on [configuration](#Config)

A manual player id-paste input is also provided to account for unexpected cases, such as late non-preregistered players or invalid URLs/exports.

## Outputs

### Teamlists

Each player's teamlist is printed before starting the tournament as an HTML file named `<GUID>.html`, where `<GUID>` represents the random GUID that VGCTourHelper assigned to that player (in order not to show any PID) under the `TeamlistOutputPath` (see [config](#Config)). If the tournament is being streamed, any time a match is selected for streaming, the teamlists of the two players in that match are printed as HTML files named after the [config](#Config) properties `Player1Output` and `Player2Output` (this time including the current swiss-score for each of them) .

### Pairings, Standings and Overlay

Overlay is printed after selecting a streamed match, Pairings are printed after each update on the tournament and Standings are printed only when a tournament phase ends (that is - the end of the swiss, the end of the first day for two-day tournaments or the end of the whole tournament). All of those are HTML files named after the corresponding `<name>Output` (`<name>` stands for "Pairings", "Standings" or "Overlay") setting on the [config](#Config) and they always overwrite. There is no way to get the Standings file other than when a tournament phase ends.

### Tournament

This file is printed after each update on the tournament and it contains the pairings for each round. It is not intended to be used for streaming purposes but it is the main HTML file that is push onto the repository for the players to see, as it shows pairings and open teamsheets. Since is not meant to be used on stream, it's output name and path are not configurable.

## Options

There are two main options that could change the flow of the application:
- **AutoUpdate** (on by default)
- **KeepDataOpen** (on by default)

**AutoUpdate**, when on, detects all changes made to any file inside the folder in which the first selected TOM file lives. On each of these changes it evaluates whether or not the edited/added file matches the structure of a TOM output and, if so, it updates the tournament data using it. In short: when you add or replace/edit TOM outputs in the folder, VGCTourHelper automatically updates the tournament.
When **AutoUpdate** is off none of this happens and you have to select the new file and click the "Update!" button to manually update the tournament.
**KeepDataOpen** keeps the internal data resources active on memory after loading them - it does not "release" the data after having printed the pastes in the paste input file. It's useful for when you have to process multiple paste inputs, being them manual or via file, because it does not need to parse and load into memory all the data for each import. After having loaded all of the pastes it should be set to "off" in order to release the memory back to the OS.

## Config

Most of the application settings are configurable: this can be done in the GUI by clicking the "Edit Config" button or by editing the [config file](./Home/Config.yaml).

The [template configuration file](./Home/Resources/config_template.yaml) shows every configurable property and its default value, used when said entry is empty or not defined on the [config file](./Home/Config.yaml).
There are a few empty properties on the template file: those are there just for you to know that they are configurable options even if not used by default. **Do NOT edit the template file, it will break the "Edit Config" behaviour!**
It's completely possible to run the application without any configuration file at all - it will run on the default values, it's actually the best approach -, the one published is this repository is just an example.

In the 99% of cases the default values are the right configuration for the app, but we are going to focus on those single settings that some users could want to edit.
- `PlayerIdFieldName` and `PasteIdFieldName` are the column names for the Paste CSV (see [here](#Inputs-and-data-files))
- `TeamlistTemplate`, `PokemonTemplate`, `PairingsTemplate`, `StandingsTemplate`, `TournamentTemplate` and `OverlayTemplate` are the HTML templates used: they can be changed in order to customize the appearance of the outputs
- `TeamlistIncludes`, `PairingsIncludes` and `StandingsIncludes` are list of JS or CSS files (separated by a space) that are included in the correlated HTML outputs's `<head>` section
- `TeamlistOutputPath`, `PairingsOutput`, `StandingsOutput`, `OverlayOutput`, `Player1Output` and `Player2Output` are the names/paths for the output files
- `GithubOutputPath` is the root destination for all the files uploaded to the Github repository
- `GithubIncludes` is the list of JS or CSS files (separated by a space) that are updated to the "resources" folder on the Github repository
- `TranslateTeamlist` determines whether or not the teamlists will be rendered in the language specified in the `Language` setting (if `LoadTranslation` is True, which is by default)

Editing the import settings (`ColumnDelimiter`, `TextDelimiter`, `FirstRowIsHeader` and `HeaderFromFirstRecord`) is heavily discouraged: since all of the VGCTourHelper internal data depends on them, modifying their values could lead to unexpected errors. It's always easier to adapt your CSV format to match the configuration than to refactor all the data files.

Inside the config the following rules apply

- all the names and values are **case insensitive**
- the `{App}` macro will be replaced by the full path on which the application is placed
- the `{TournamentName}` macro will be replaced by the name of the tournament - be careful as this macro is available only for tournament-related settings, not for data-settings
- all of the names can be used in templates as macros with the `%Config:SettingName%` syntax
- any custom setting can be added and then used as a macro with the same `%Config:SettingName%` syntax

## Templates

### [Teamlist](./Home/Resources/teamlist.html)

It's one of the only two mandatory template files: it should contain the basic structure of an HTML file with the specific `%INCLUDE:Teamlist%` macro in its `<head>` section (which works as an "anchor" to insert the include files mentioned in the [config section](#Config)), any number of macros on the player data (as `%FirstName%` or `%Wins%`) and the special macro `%Team%`, which will be replaced with one entry of the [pokémon template](#Pokemon) for each member of that player's team.

### [Pokemon](./Home/Resources/pokemon.html)

The other mandatory template file, it should contain just a HTML fragment that represents a pokemon in a team.
In addiction to macros on the pokemon data (such as `%PokemonIndex%`, `%Ability%`, `%Item%`, ...) it can contain the "indexing bracket macros", written as `<%MacroName%>`, that repeat everything that's inside them as many times as needed, replacing the keyword `#n#` with the index of the iteration. It's actually simpler than it seems: take a look at the following portion

```html
<%Moves%>
  <div class="move-#n#">
    <div class="move-sprite">
      <img class="img-move-sprite type-sprite" src="%Config:AssetsUrl%%Config:TypeAssetsFolder%%Move#n#Type%.png">
    </div>
    <div class="pokemon-text move">%Move#n#%</div>
  </div>
<%Moves%>
```
`%Move#n#%` intuitively will be replaced with the name of the `n`-th move, with `n` likely going from 0 to 3 (but not necessarily, am I right Fake Out + Last Resort Kangaskhan?), while `%Move#n#Type%` will be replaced by that move's type name.

### Pairings and Standings

There are no default file for those template as they are built-in inside the application itself. All of those templates contain the basic structure of an HTML  file, each one with its `%INCLUDE:<name>%` macro in the `<head>` section, that matches the `%<name>Includes%` property on the [config](#Config) (`<name>` stands for "Pairings" or "Standings"). In addiction to that, those templates should contain, in the `<body>` section, the `%<name>%` macro, which will be replaced with the actual HTML content.

### Tournament

It's the same as [pairings and standings](#Pairings-and-Standings) with the only difference that in the `<body>` section, instead of the `%Tournament%` macro, the `%RoundsHeader%` and the `%RoundsContent%` are used (and they represent all the rounds of the tournament).

### Overlay

This is the only template without default (neither built-in nor a file): if no file is specified in `OverlayTemplate` on the [config](#Config) (or when that file does not exist), the overlay output is simply not rendered. No specific includes are expected for this output, since it does not rely solely on VGCTourHelper. The app just provides the needed data of the two players in the match: player 1 data is retrievable using `%P1:PropertyName%` macros while player 2 data is retrievable using `%P2:PropertyName%` macros.

## License

All of the VGCTourHelper code code is distributed under the terms of the [**Apache License 2.0**](./LICENSE).

### Third-Party Code Notice

This project includes portions of code from the [*Synopse mORMot 1 framework*](https://github.com/synopse/mORMot), used under the terms of the [**Mozilla Public License 1.1 (MPL 1.1)**](http://www.mozilla.org/MPL/MPL-1.1.html).

The relevant files are located in the directory [`Source/ThirdParty/`](./Source/ThirdParty)

These files remain under the MPL 1.1 license and are not covered by the Apache License 2.0 applied to the rest of this project.
Minor modifications have been made to [one file](./Source/ThirdParty/SynCrypto.pas) (i.e. changes to variable values within a function call). 
Per MPL 1.1, the modified file continues to be distributed under the same MPL 1.1 license, with the original license headers preserved.

## Code details

Additional details on code structure can be found [here](./Docs/CODE.md).

## Contact us

If you have any feedback, suggestion or any comment, here is where you can find us:
- [relder](https://x.com/reldervgc) - Developer
- [shairaba](https://x.com/shairaba) - Project manager