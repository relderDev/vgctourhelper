# The code

VGCTourHelper is an application written in Delphi, in this file we will go through a brief explanation of how the code is structured.
But first

## Why Delphi

Starting off with what is always the first question: why Delphi?
Delphi has numerous advantages over other programming languages, we could spend all day talking generally about its great feats like high performances or the usefulness of its IDE, but, instead, I think it's best to give a few practical reasons to why I almost didn't consider other languages for this project.
1. I do already use Delphi in my work environment - this means I'm faster at writing Delphi code and I have a bunch of utilities ready-to-use that I don't have to search for and learn/rewrite from scratch
2. Creating a GUI can be done extremely faster and in a much easier way than any alternative I tried
3. Since the TOM software is available for both Windows and MacOS, it feels just right to use a tool that can target both platforms with one codebase, as Delphi does
4. This application should be fast, lightweight and as "invisible" as possible, processing tournament updates in background and updating both the online page and the streaming - Delphi was just perfect for this use case: in most cases the application will run on the same machine that runs the streaming; being as little resource-consuming as possible is a must
5. The application can be compiled with Delphi CE, which is free ([download it here](https://www.embarcadero.com/products/delphi/starter/free-download))

With this out of the way, let's proceed

## Unit descriptions

### AKLib

The units under the folder [AKLib](../Source/AKLib) are part of the personal library of utilities of mine. I'm constantly using them and working on them: for this reason I have not released a full version of that library yet, but I will do in the future. Those units are used as a foundation for data and I/O handling as well as parsing. Makes use of some Indy libraries.

### ThirdParty

The units under the folder [ThirdParty](../Source/ThirdParty) are part of the [*Synopse mORMot 1 framework*](https://github.com/synopse/mORMot) and are used solely to handle encryption for the repository token.

### Pokemon

`Pokemon.Constants.pas`, `Pokemon.Data.pas`, `Pokemon.Context.pas`, `Pokemon.pas` are the units that handle all the basic configuration, the resource data (the CSV files) and the PokePaste parsing. `Pokemon.Context.pas`, in particular, is designed to provide a context to all of the units as a global singleton instance.
All of the pokemon logic and data is enclosed onto this units.

### VGC

`VGCPlayer.pas`, `VGCTournament.pas`, `VGCStreaming.pas` contain all tournament-oriented logic: from players and results to printing the teamlist for the players on stream. More specifically, `VGCStreaming.pas` adds both the printing methods and repository handling to the base class defined in `VGCTournament.pas`, that takes care of the main flow of the tournament.
With this section the **core** part of the application is done, this and the previous sections contain all of the VGCTourHelper logic.

### FMX

Units under the folder [FMX](../Source/FMX) contain all the GUI logic, from the main form to the support forms (config edit and folder listener), the main form unit specifically links the tournament logic to the GUI controls.

### UseAKLib.pas

This unit is here only to set an encryption key for the application's encrypter.
**Remember to edit this unit before compiling in order to set one for your installation!!**

## Contact me!

If you have feedbacks, suggestions, doubts or if you are just curious about something in the code, feel free to [hit my DMs!](https://x.com/reldervgc)