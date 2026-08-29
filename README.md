<div align="center">

# 🔥⛺ bonfire

**A locally-served new tab page that follows your Noctalia theme**

![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=flat&logo=nixos&logoColor=white)
![Firefox](https://img.shields.io/badge/Firefox-FF7139?style=flat&logo=firefox&logoColor=white)

</div>

https://github.com/user-attachments/assets/30284c25-3eae-47a0-944a-e4384f1dc940

> [!WARNING]  
> This is a private project that I thought would be cool to share. If it doesn't work, feel free to create an issue and I'll see what I can do. But please don't expect me to fix it.

## Why though

I really enjoy Noctalia with its wallpaper-generated themes. I added templates pretty much everywhere and love the uniform look.
One thing that bothered me was the fact that the new tab was pretty empty. I liked that it changes colors as well, but I wanted to have a cool new tab page with extra things displayed.
However there isn't really any good solution (as far as I know) that allow a customized new tab + automatically changing themes from Noctalia.
(Probably one reason being that firefox extensions [cannot access local files](https://bugzilla.mozilla.org/show_bug.cgi?id=1266960) due to security reasons.)

This is also the reason we are instead hosting a local server that serves the page, allowing us to override a new tab with the locally hosted URL.

## Features

- Clock
- Quicklinks (no quick-setting to change them yet)
- Searchbar (using duckduckgo, also no quick-setting to change it yet)
- Cool Wave-Shader as a background (psp vibes)
  
## How to install

### Requirements

- Browser with WebGL support
- JetBrains Mono NerdFont
- Noctalia (the home-manager module needs to be imported, even if you disable the template option)

---

### NixOS (Nix Flake)

I created a nix flake that will add a home-manager module to your config.

Add inputs to the `flake.nix` of your nix-config:
```
inputs = {
  bonfire = {
    url = "github:honklam/bonfire";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Also add bonfire in `sharedModules` for Home-Manager access:
```
home-manager.sharedModules = [
	    inputs.bonfire.homeManagerModules.default
];
```
Then add the following to your `home.nix` or create a separate `bonfire.nix` file:
```
{ ... }:
{
  programs.bonfire.enable = true;
}
```

You can configure the following things:
```
programs.bonfire = {
  enable = true;
  port = 8420;                                    # port for the local webserver
  dataDir = "${config.xdg.dataHome}/bonfire";     # where the static files live
  noctaliaTemplate = true;                        # auto-load noctalia theme colors
};
```
(the values above are the defaults, so you only need `enable` to get going. With `noctaliaTemplate = false` the page falls back to hardcoded colors)

The module itself will then do the following:
- sync the static files from the nix store (in case something updated) to the correct location
- place in `noctalia/templates/` a user-made template called `bonfire.css`
- tell noctalia to use this template
   - noctalia renders the `bonfire.css` template with the correct colors and writes the file next to the static files
- run a [super basic http server](https://github.com/emikulic/darkhttpd) and point it to the static files as a systemd service

---

### `install.sh` Script

I created a `install.sh` script. Use it to install bonfire (almost automatically):

```
git clone https://github.com/HonKLam/bonfire.git
cd bonfire
cat install.sh
chmod +x install.sh && ./install.sh
```
(`cat install.sh` since you should always look through the script first before running it! ^^)

If install was successful, you need to manually add the noctalia user-template to your
`noctalia/config.toml` file:

```
[theme.templates.user.bonfire]
input_path  = "/home/YOU/.config/noctalia/templates/bonfire.css"
output_path = "/home/YOU/.local/share/bonfire/colors.css"
```

Refresh wallpaper and everything should be working!

To uninstall and clean everything up, simply:
```
cd bonfire
cat unisntall.sh
chmod +x uninstall.sh && ./uninstall.sh
```

---

### Anything else (manual way)

- clone the repo
- make a systemd service that will run a http server pointing at the repo
- create a `bonfire.css` in `noctalia/templates` directory and copy in the following:

```
:root {
  --m-surface:            {{colors.surface.default.hex}};
  --m-surface-variant:    {{colors.surface_variant.default.hex}};
  --m-on-surface:         {{colors.on_surface.default.hex}};
  --m-on-surface-variant: {{colors.on_surface_variant.default.hex}};
  --m-primary:            {{colors.primary.default.hex}};
  --m-secondary:          {{colors.secondary.default.hex}};
  --m-tertiary:           {{colors.tertiary.default.hex}};
  --m-outline:            {{colors.outline.default.hex}};
}
```

- In noctalia config, you need to add the user template, so noctalia knows where the rendered output should go:

```
[theme.templates.user.bonfire]
input_path  = "~/.config/noctalia/templates/bonfire.css"
output_path = "/path/to/bonfire/src/colors.css"
```

> [!IMPORTANT]  
> Please make sure the output-file is called `colors.css`


## How to use after install

When everything is set up and running, you should be able to access the webpage through URL (`http://127.0.0.1:8420/`, or whatever port you configured).
You can now use extensions like [New Tab Override](https://addons.mozilla.org/en-US/firefox/addon/new-tab-override/) and set it with the following settings:
- Option: Custom URL
- Manage URL Rules:
  - URL: http://127.0.0.1:8420 (or just your correct page)
- Focus: `Set focus to the web page instead of the address bar` --> CHECK it

--> Opening a new tab should display the new tab, yaaaaay

> [!NOTE]  
> Already-open tabs check for a new palette every 500ms, so switching your theme takes a moment to show up. Newly opened tabs have the correct colors immediately.

## Contributing

Feel free to contribute by sharing this project, reporting issues or creating PRs. In order to develop easily, there is also a simple devShell for nix users:

Just clone the repo and run:
```
nix develop
```

It should install [live-server](https://www.npmjs.com/package/live-server) and symlink the colors.css from your nix installation into `src/` (if you used the nix install way)

Then in devShell just:
```
live-server src -p 8421
```
And you should easily be able to work on this!
