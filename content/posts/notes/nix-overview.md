---

title: "Nix Overview"
date: 2024-08-09T10:12:06+08:00
author: John Wu
summary: An overview of NixOS and my experience switching over to it
ShowToc: true
draft: false

---

Recently I switched from Arch Linux to NixOS on my laptop.
This article is my experience of converting from standard Linux distros (I've used Debian derivatives, Fedora, Arch Linux, and Windows) to a declarative one like NixOS.

# Initial setup
The worst part of NixOS is post installation and the first setup.
The NixOS installer uses a legacy declarative system, `configuration.nix` and `hardware-configuration.nix`.
While using `configration.nix` does work, it's not way most people do it now, and the majority of the time learning is from other people's configs.

The modern way to write configurations for NixOS is using flakes.
I still don't fully comprehend the concept of flakes, but here's my understanding:
A flake is defined through one file: `flake.nix`, and it is nix code that can define the environment using a given set of other flakes.
That's pretty confusing, I would recommend reading [this reddit comment](https://www.reddit.com/r/NixOS/comments/131fvqs/can_someone_explain_to_me_what_a_flake_is_like_im/).

> As a side note, install NixOS with a bigger than average `/boot` partition, it will be useful when you need to store many past generations to rollback to.

## Flake.nix Structure
Inside the `flake.nix` file, there is an input and an output.
You can think of the input as a repo list, it dictates where packages are programs are coming in from.
The outputs of a flake.nix is the part that actually dictate what your system looks like.
For example, if I wanted to add the stylix program to my nix flake, here is the code for it:
```nix
{
  # INPUTS SECTION
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix";
  };
  # OUTPUTS SECTION
  outputs = { nixpkgs, stylix, ... }: {
    nixosConfigurations."«hostname»" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ stylix.nixosModules.stylix ./configuration.nix ];
    };
  };
}
```
Code snippet taken from [stylix docs](https://stylix.danth.me/installation.html).

### Inputs explanation
The inputs section first defines a set of inputs, in this case nixpkgs and stylix.
Nixpkgs is the repository for nixOS, where you'll find GNU coreutils, Linux, and [others](https://search.nixos.org/).
This ends the input function, as you can see, it's pretty much just a list of repositories like you would find in `/etc/apt/sources.list` on Debian.

### Outputs explanation
The outputs section starts utilizing the inputs and also are where nix code is more useful.
In this output, you can see that we take in `nixpkgs` and `stylix` as an input.
We then define that we are editing nixosConfigurations and the hostname.
Then we add the `configuration.nix` as a module to the flake.
This means that the default `configuration.nix` can still be used in a flake, we just add it to the flake as a module.
Everything in `configuration.nix` then becomes the "output" of our flake.
The output of the flake defines the environment, and that is the general concept of a flake.

When I first started, these concepts were never defined clearly to me.
I couldn't tell what they were for and why I needed it.

## Post Flake setup
After setting up flakes, there are many things you need to setup in order to have your setup look more organized.
I made the mistake of being TOO modular, following [librephoenix's](https://github.com/librephoenix/nixos-config/) configuration.
It was too modular because I had 1 file inside 1 directory, for example the zfs directory would only have a `zfs.nix` file.
Making it too modular can make programming around the project more difficult.

However, it is also not good to have it all in one file.
This is where the module functionality in the nix language is useful.

### Using the home-manager as a NixOS module
There are two main ways to use home-manager: home-manager as a module to NixOS and home-manager standalone.
This is documentated [here](https://nix-community.github.io/home-manager/).

I installed home-manager as a NixOS module because in order to have impermanence (explained later), home-manager must run as a module.
The main difference between the two are build times.
Just like building a project, NixOS requires that you build your operating system.
- In a standalone installation, you would rebuild home-manager with `home-manager --flake /path/to/flake/dir switch`
- In a modular installation, you would rebuild home-manager with `sudo nixos-rebuild --flake /path/to/flake/dir switch`
In the modular installation, you are rebuilding the whole operating system, so both your userspace and system level packages, services, and others will be rebuilt.
Don't worry though, nothing will randomly break on you (usually) when you rebuild things.
A feature of flakes is having a lock file, it locks the versions of programs that is installed so that even if you move to a new system, you can be sure that nothing will change and be on another version.

The community docs for installing home-manager is not very declarative, meaning if you moved to a new system you have to manually type new commands.
Here is how I installed it to be declarative:
```nix
{
  nixosConfigurations = {
    nixon = lib.nixosSystem {
      system = systemSettings.system;
      modules = [
        ./path/to/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
  
            extraSpecialArgs = {
              inherit pkgs-unstable; # must have an input called pkgs-unstable
              inherit inputs;
            };
  
            users.${userSettings.username} = {
              imports = [ ./path/to/home.nix ];
            };
          };
        }
      ];
      specialArgs = {
        inherit pkgs; # must have an input called pkgs
        inherit pkgs-unstable;
        inherit inputs;
      };
    };
  };
}
```

# Why use flakes?
## Atomicity
Flakes are an extremely useful tool because you can be sure that every install you do will become the same.
With the traditional `configuration.nix`, everytime you move to a new machine, you must pull from the channel the system is on.
For example, if system A is on nixpkgs-23.11, and a package such as gzip is updated on 23.11, then when you install with the same configuration on the new system, the new system is running the new gzip version.
This is why the flake.lock file exists, so that new installations will not have varying versions of programs.

Varying versions of packages will at best give you new features in a newer version and at worst it will create breaking changes because of individual package updates.

## Bootstrapping
Bootstrapping systems with nix flakes is a much easier process than the traditional.
The traditional method requires pulling down the `configuration.nix` file and then rebuilding.
With flakes, you don't even have to download the file, you can just build the flake while reading from remote.
You can also define multiple systems in one flake.
For example, you can define `host_server`, `virtual_guest`, or `personal_computer` all in one flake.
Then you can just build which system you want.

# Documentation
Documentation in NixOS is notoriously difficult to read and find.
I think the reason it's hard to read is because most of it is in the source code, which is written in nix.
Someone unfamiliar with the basics of the language would have a hard time reading the documentation.
I haven't had much of a problem with documentation mainly because I only use nix to define my personal laptop.
Maybe if I were contributing to nixpkgs or a developer of nix, I would understand more about the lacking documentation

For most people using nix, all we need is [mynixos.com](https://mynixos.com/).
This site provides all the details about nixpkgs that you need.
I will go through an example of configuring [sanoid](https://github.com/jimsalterjrs/sanoid/) in nix.

If you search for sanoid on mynixos.com, you will see options for [services.sanoid.enable](https://mynixos.com/nixpkgs/option/services.sanoid.enable), [services.sanoid.package](https://mynixos.com/nixpkgs/option/services.sanoid.package), and others.
Clicking on these options will give you an example and description.
If you add these options to your system configuration you can enable and set the package of sanoid, like this:
```nix
services.sanoid.enable = true;
services.sanoid.package = pkgs.sanoid;
```
You can also shrink this down with a set like so:
```nix
services.sanoid = {
    enable = true;
    package = pkgs.sanoid;
}
```
To specify datasets, there are no examples for [services.sanoid.datasets](https://mynixos.com/nixpkgs/option/services.sanoid.datasets).
However, it does say that it's an attribute set.
You have to read the source code to understand how to write this.
So the code could look like this to snapshot my home and var datasets:
```nix
services.sanoid = {
    enable = true;
    package = pkgs.sanoid;
    datasets = {
        "rpool/home" = {
            daily = 24;
            hourly = 4;
            weekly = 2;
            monthly = 1;
        }
        "rpool/var" = {
            daily = 1;
            hourly = 1;
            weekly = 1;
            monthly = 1;
        }
    }
}
```

# Erase your Darlings
This is my favorite feature of NixOS, I don't know how useful it is, but it's pretty sick.
The name erase your darlings comes from an [article](https://grahamc.com/blog/erase-your-darlings/) called erase your darlings.
The author is a pretty active maintainer of nix projects.

NixOS doesn't need many things to run, all it needs is the boot partition and a nix-store partition.
This means that anything in traditional distros is not needed and can be wiped every boot.
Taking this concept, upon every boot, my whole system including the home directory is stored in tmpfs, or RAM.
The persistent things you want to keep, you can store it in a partition and symlink the persistent stuff over every boot.
The benefit of this are:
- A cleaner system
- Forcing every configuration to be declarative so it can't be wiped upon reboot
- Speed?
- It's just cool

Erasing your darlings is probably another blog post, so I will link how others have done it here:
- https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
- https://github.com/hyperboly/nix-dotfiles/blob/master/system/impermanence.nix

# Comparison to Ansible
## System agnostic
While learning nix, I was also learning how to use ansible to automate my servers.
The major upside to using nix is that it is system agnostic.
For example, if I wanted to install a package, I just use nixpkgs.
On ansible, I would have to specify the package manager to install a program.

Of course, this creates a limitation of nix.
Ansible can be run on a variety of systems including Windows and BSD, a feat that nix can't do (well).

## Language differences
Ansible is configured in YAML, which is a really stupid configuration language, while nix is configured in the nix language, which is not ideal.

I don't think I have to explain why YAML is stupid.
YAML is an indentation freak, it gets quite confusing after the 5th indentation, it's hard to read...

The nix language is not that bad, especially currently in 2024.
The problem I have with it is that it's a new language when they could've used an existing one.
I've never learned purely functional languages but if nix was built using a more recognized language, I would at least have a new skill that's useful outside of nix.

Either way, I think both languages are fine, especially at the scale that I'm using it at.
In small projects and dotfiles, both tools are acceptable linguistically.

## Reproducibility
Nix fundamentally is always going to be more reproducable than Ansible.
When Ansible installs a package, it is using the system package manager that does not have a lock file for program versions.
In nix, as explained, using a flake means the packages will have the same version across all systems you are installing on.

I would recommend listening to [this talk](https://www.youtube.com/watch?v=0uixRE8xlbY) given on why use flakes and not docker.
In short, the same problem arises with docker.

Thanks for reading, I use nix btw.
