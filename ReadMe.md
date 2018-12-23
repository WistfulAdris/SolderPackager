# SolderPackager

## Description

Unlike other modpack distribution system, TechnicLauncher allows modularizing mods for a modpack. This is awesome, because it allows users to only have to download changes when modpack is updated, without having to download the whole pack again. However, due to the nature of the TechnicSolder and its repository database schemea, modpack developers must package mods individually, which can be very time consuming. 

While there are other existing tools to help you package your mods, most of them are either abandoned, not cross-platform, not automated enough, or simply doesn't work well. This program is written in Ruby, which is very flexible and can run on many different platforms since Ruby doesn't have a compiler. Although it is not tested, this should run fine on macOS or Windows as long as environment for Ruby is setup properly.

This program is under development. Currently it lacks uploading feature and updating database for Solder automatically upon upload. It can however take all mods in a given folder, generate a nice configuration file from mcmod.info/litemod.json and with minimal modification, which this program will use the config to create Solder-ready .zip file, so that all you have to do is upload them and update the Solder database afterwards.

## License

This program is licensed with GPL v2.0. This means that you can use it however you want, but if you decide to change the code, you are required to put a link to the original source (this page) and share the code you've changed from the original. This is so that people can easily use the program without having to worry about license and to allow this program to be developed without being abandoned.

## Running

There are few requirements for running this program. Although the environment can vary and the program might run on a different environnment than it is listed on here, this is what is officially supported.

&nbsp; | Supported Versions
----: | :----------
Ruby | 2.5 and above
Ruby | Must have 'rubyzip' gem installed. 
OS | GNU/Linux, Windows 7 and above, macOS Yosemite and above

To run this program, simply clone this repository, add mods to 'mods' folder and run "ruby run.rb". This should automatically grab mods from the mods folder and generate appropriate configuration file. It will prompt you to check configuration file at config/mods.yml, which you should than check for any mods that has "N/A" in "version:". Next, you should get the version of the mod, change version and trim the modname so that it only includes modname.

For instance:

iamamod-1.2.jar:
   version: N/A
   filename: iamamod-1.2.jar
   
Should be:
    
    iamamod:
    version: 1.2
    filename: iamamod-1.2.jar.
    
As this program grabs information from mcmod.info/litemod.json, you shouldn't have to do this for most of your mods. This is just a workaround for mods that doesn't have necessary information, or when that file is not accessible.

## Bugs & Issues

Any bugs and issues should be reported at "Issues" tab, with following information:

- Your operating system: 
- Ruby version:
- Issue:

Without the information above, I will not be able to reproduce the issue, which will make it impossible for me to resolve. You are strongly encouraged to give as detailed information regarding bug/issue as in depth as possible. 

## Feature Requests

You are more than welcome to open a new requst for features in the "Issues" tab. If you could include how to implement that feature and why, it would make my life much easier. Even better, submit a pull request!

## Pulls (Pull Request or PRs for short)

When submitting a pull request, make sure that your code is well commented and that your code is actually working. I will not be merging any PRs that is poorly written, missing comments and with poor programming style. In addition, your commit should include:

- filename you've modified
- what it does
- why it is necessary

For instance:

run.rb: add support for x to allow y z

## Further Reading

If you would like to learn more, simply refer to the code itself. It shouldn't be too hard to understand, since most of the code is documented using comments. If you have any questions, feel free to ask.
