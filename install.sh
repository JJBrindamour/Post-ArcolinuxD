#!/bin/bash

# Update the system
pacman -Syyu

# Install Pacman Packages
pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack pamixer chaotic-mirrorlist chaotic-keyring lxappearance kvantum grub-customizer openbox bspwm sxhkd sddm alacritty vim nano micro thunar geany sddm zsh dunst wget neofetch nitrogen plank polybar ranger rofi starship firefox arandr carla flatpak wine

# Chaotic AUR
echo "\n[chaotic-aur]\ninclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
pacman -Syy

# Install Yay
git clone https://aur.archlinux.com/yay.git "$HOME"/yay
(cd "$HOME"/yay && makepkg -si)

# Install AUR Packages
yay -S betterlockscreen spotify cava github-desktop networkmanager-dmenu-git

# Install Configs
mv ./.config/* "$HOME"/.config/
mv .bashrc "$HOME"/.bashrc
mv .zshrc "$HOME"/.zshrc

# Betterlockscreen
betterlockscreen -u "$HOME"/.config/wallpaper.jpg

# Music
echo "Do you want to install music production tools? (y/N) "
read instmusic
if [[ $instmusic == "y" || $instmusic == "Y" ]]; then
	pacman -S yabridge yabridgectl reaper dexed calf fluidsynth avldrums.lv2 caps cardinal-lv2 dpf-plugins dragonfly-reverb drumgizmo ebumeter eq10q fabla geonkick guitarix helm-synth hydrogen liquidsfz lsp-plugins mda.lv2 ninjas2 noise-repellent qjackctl samplv1 setbfree sherlock.lv2 sonic-visualiser surge swh-lugins tap-plugins vamp-plugin-sdk wolf-shaper wolf-spectrum x42-plugins zam-plugins zynaddsubfx
	cp ./music-installers/* "$HOME"/music-installers/
	echo "\n\n---  Installers for other instruments that are not in the standard repos are in ~/music-installers  ---\n\n"
fi

# Games
echo "Do you want to install gaming tools? (y/N) "
read instgames
if [[ $instgames == "y" || $instgames == "Y" ]]; then
	pacman -S steam lutris
	wget $(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "tag_name" | awk '{print "https://github.com/GloriousEggroll/proton-ge-custom/archive/" substr($2, 2, length($2)-3) ".tar.gz"}')
	mkdir -p "$HOME"/.steam/root/compatibilitytools.d
	tar -xf GE-Proton*.tar.gz -C ~/.steam/root/compatibilitytools.d/
	yay -S heroic-games-launcher-bin
fi

# Grub
echo "Do you want to install custom grub theme? (y/N) "
read instgrub
if [[ $instgrub == "y" || $instgrub == "Y" ]]; then
	git clone https://github.com/vinceliuice/grub2-themes.git "$HOME"/grub-themes
	"$HOME"/grub-themes/install.sh -b -t vimix -i white	
	update-grub
	grub-install
fi

# Openbox & GTK Theme
git clone https://github.com/archcraft-os/archcraft-themes.git "$HOME"/archcraft-themes
mv "$HOME"/archcraft-themes/archcraft-gtk-theme-nordic/files/Nordic/* /usr/share/themes/nordic/

# SDDM
systemctl enable sddm
mv ./sugar-candy/* /usr/share/sddm/themes/sugar-candy/
cp "$HOME"/.config/wallpaper.jpg /usr/share/sddm/themes/sugar-candy/Backgrounds/
mv ./kde_settings.conf /etc/sddm.conf.d/kde_settings.conf

