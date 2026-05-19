#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if script is run as root
if [[ "$(id -u)" -eq 0 ]]; then
  echo "This script must not be run as root"
  exit 1
fi

#---- Programs List ----------------------

declare -a minimal=(
	acpi alacritty autotiling axel base-devel bc blueman bluez bluez-utils brightnessctl bspwm btop \
	conky copyq ddcutil dmenu drawing dunst envycontrol fcitx5 fcitx5-configtool fd feh file-roller firefox flameshot \
	fluent-cursor-theme-git font-manager fzf g4music-git gammastep geany gnome-calculator gnome-desktop gnome-desktop-4 \
	gnome-disk-utility gnome-epub-thumbnailer gping gpu-screen-recorder jq gpick grep python-gtts html-xml-utils htop \
	i3lock-color i3-wm imagemagick jgmenu kdeconnect libplasma linux-wifi-hotspotkvantum kvantum-qt5 loupe man moreutils mpv \
	mpv-mpris mugshot ncdu network-manager-appletnetworkmanager-openvpn noto-fonts noto-fonts-cjk noto-fonts-emoji \
	nsxiv nvtop oh-my-zsh-git openbox openssh openvpn papirus-icon-theme pastel pavucontrol qt5ct qt6ct \
	rofi ruby-fusuma ruby-fusuma-plugin-sendkey scrot sioyek-git stalonetray subliminal-git \
	snapshot sxhkd termdown thunar thunar-archive-plugin papers perl picom-git plank playerctl polkit-gnome \
	polybar python-pyxdg python-screeninfo python-wheel qbittorrent songrec thunar-media-tags-plugin thunar-volman \
	ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-nerd-fonts-symbols \
	ttf-nerd-fonts-symbols-common timeshift tumbler translate-shell waypaper wget wmctrl xcape xclip \
	xdg-autostart xdg-user-dirs xdg-user-dirs-gtk xdo xdotool xfce4-power-manager xfce4-settings xiccd \
	xorg-xdpyinfo xorg-xkill xorg-xrandr xorg-xrdb xorg-xsetroot xorg-xwininfo xss-lock yad ytfzf zathura \
	zathura-cb zathura-pdf-mupdf zenity zsh zsh-autosuggestions zsh-syntax-highlighting
)

declare -a extra=(
	anki audacity baobab blanket discord flatpak gimp github-desktop gnome-clocks gnome-system-monitor \
	gnome-weather gparted gping handbrake heroic-games-launcher-bin jdk-openjdk telegram-desktop krita \
	libreoffice-fresh lutris mangohud megatools mkvtoolnix-cli obs-studio openboard polychromatic scrcpy \
	soundux spicetify-cli spotify stacer steam syncplay syncthing teamviewer trackma-git video-trimmer \
	virtualbox visual-studio-code-bin wine winetricks
)

declare -a wayland=(
	cliphist grim hypridle hyprland hyprlock hyprpicker hyprsunset nwg-displays slurp swappy swww \
	quickshell-git python-opencv xdg-desktop-portal-hyprland python-pywayland wl-clipboard  matugen-git\
	syntax-highlighting
)

declare -a aur=(
	i3-resurrect mpv-thumbfast-git mpv-uosc-git ttf-rubik-vf ttf-gabarito-git \
	tty-clock unimatrix-git xqp
)

declare -a additional=(
	ookla-speedtest-bin typioca-git 
)

#---- Core functions ---------------------

checkrepo(){
	chaotic="$(grep -i "chaotic" /etc/pacman.conf | head -n1)"
	if [[ "$chaotic" == "[chaotic-aur]" ]]; then
		echo "The Chaotic AUR repo is already added"
	else
		echo "Adding the Chaotic AUR repo"
		# Import and sign Chaotic AUR repository key
		sudo pacman-key --recv-key "3056513887B78AEB" --keyserver keyserver.ubuntu.com || exit 1
		sudo pacman-key --lsign-key "3056513887B78AEB" || exit 1

		# Add Chaotic AUR repository to pacman.conf
		sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
		'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm || exit 1 &&
		echo "[chaotic-aur]
		Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
	fi

	if ! pacman -Q yay &> /dev/null; then
		echo "Installing the AUR helper yay..."
		sudo pacman -Sy yay --noconfirm
	else
		echo "The AUR helper yay is already installed"
	fi

	# Configure pacman
	sudo sed -i "s/#ParallelDownloads = .*/ParallelDownloads = 10/g" /etc/pacman.conf
	sudo sed -i "s/#Color/Color/g" /etc/pacman.conf
	sudo sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf
}

install_minimal(){
	yay -Syu ${minimal[@]} ${aur[@]} --needed --noconfirm
}

install_wayland(){
	yay -Syu ${minimal[@]} ${wayland[@]} ${aur[@]} --needed --noconfirm
}
	
install_full(){
	yay -Syu ${minimal[@]} ${wayland[@]} ${aur[@]} ${additional[@]} --needed --noconfirm
}

wayland_install(){
	checkrepo &&
	install_wayland &&
	xdg-user-dirs-update &&	xdg-user-dirs-gtk-update
	move_configs
	file_check
	change_theme
	install_sddm
	install_zsh
	install_wpgtk
}

x11_install(){
	checkrepo &&
	install_minimal &&
	xdg-user-dirs-update &&	xdg-user-dirs-gtk-update
	move_configs
	file_check
	change_theme
	install_sddm
	install_zsh
	install_wpgtk
}

move_configs(){
	cp -r "$dir"/cfg/* "$HOME"/.config && echo "moved config files"
	cp -r "$dir"/bin/.local/ "$HOME" && echo "moved bin"
	cp -r "$dir"/deps/.zprofile "$HOME"

    mkdir -p "$HOME/.local/share/icons"
}

change_theme(){
	dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	xfconf-query -c xsettings -p /Net/ThemeName -s "FlatColor"
	xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"	
	cat "$dir/cfg/plank/plank.conf" | dconf load /net/launchpad/plank/docks/
	cp -r "$dir"/bin/.icons "$HOME"

	if [[ -d  "/usr/share/icons/Papirus" ]]; then
		sudo chgrp -R $(whoami) /usr/share/icons/Papirus
		sudo chmod -R ug+rwX /usr/share/icons/Papirus
	fi
}

install_wpgtk(){
	sh "$dir"/bin/.local/bin/wpgtk --run &&
	if "$Dialog" --yesno "Do you want your Login Screen background to sync with your wallpaper?
		(This only works with the included SDDM theme)" 20 60 ;then
		"$dir"/bin/.local/bin/wpgtk --lock &&
		"$dir"/bin/.local/bin/wpgtk --set "$dir"/deps/background.jpg
	else
		"$dir"/bin/.local/bin/wpgtk --set "$dir"/deps/background.jpg
	fi
}

#---- Additional configurations ----------

install_zsh(){
	## Check and set Zsh as the default shell
	[[ "$(awk -F: -v user="$USER" '$1 == user {print $NF}' /etc/passwd) " =~ "zsh " ]] || chsh -s $(which zsh)

	## Install Oh My Zsh
	#if [ ! -d "$HOME"/.oh-my-zsh/ ]; then
	  #sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	#else
	  #omz update
	#fi

	## Install Zsh plugins
	#[[ "${plugins[*]} " =~ "zsh-autosuggestions " ]] || git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

	#[[ "${plugins[*]} " =~ "zsh-syntax-highlighting " ]] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	cp "$dir"/deps/.zshrc "$HOME"
}

install_sddm(){
	# Check if SDDM is installed and install if not
	echo "Making sure that SDDM is installed"
	sudo pacman -S sddm plasma-framework5 libplasma --needed --noconfirm

	# Move sddm theme files
	if [ ! -d "/usr/share/sddm/themes/Chili" ]; then
		sudo cp -R "$dir"/deps/Chili  /usr/share/sddm/themes/
	fi
	
	# Copy profile picture to user directory
	cp "$dir"/deps/.face "$HOME"

	# Create the directory for the sddm configuration files
	sudo mkdir -p "/etc/sddm.conf.d/"

	# Write the sddm theme configuration to a file
	# Redirect output to /dev/null to hide any console output
	# Use a heredoc to specify the configuration text
	sudo tee "/etc/sddm.conf.d/theme.conf" > /dev/null <<-EOF
	[Theme]
	Current=Chili
	CursorTheme=Fluent-dark-cursors
	DisableAvatarsThreshold=3
	EnableAvatars=true
	FacesDir=/usr/share/sddm/faces
	Font="JetBrains"
	ThemeDir=/usr/share/sddm/themes
	EOF

	# Disable currently enabled display manager
	if systemctl list-unit-files | grep enabled | grep -E 'gdm|lightdm|lxdm|lxdm-gtk3|sddm|slim|xdm'; then
	  echo "Disabling currently enabled display manager"
	  sudo systemctl disable $(systemctl list-unit-files | grep enabled | grep -E 'gdm|lightdm|lxdm|lxdm-gtk3|sddm|slim|xdm' | awk -F ' ' '{print $1}')
	fi

	# Enable SDDM
	echo "Enabling SDDM"
	sudo systemctl enable sddm
}

file_check(){
	# Define directories to search
	directories=(quickshell hypr bspwm openbox i3 polybar jgmenu rofi)
	
	# Find and make script files executable
	for dir in "${directories[@]}"; do
	    find "$HOME/.config/$dir" "$HOME/.local/bin" -type f 2>/dev/null | \
	    while read -r file; do
	        if file "$file" | grep -q "script"; then
	            chmod +x "$file"
	        fi
	    done
	done
}

install_firefox_theme(){
	cp -rb "$dir"/deps/firefox/user.js "$HOME"/.mozilla/firefox/*.default-release/ && echo "User Profile Copied Successfully"
	cp -rb "$dir"/deps/firefox/chrome "$HOME"/.mozilla/firefox/*.default-release/ && echo "Chrome CSS Copied Successfully"
}


# Update or clone the wallpapers repository
wallpapers() {
    if [[ -d "$HOME/Pictures/Wallpapers/Wallpapers.git" ]]; then
        cd "$HOME/Pictures/Wallpapers/Wallpapers.git" && git pull
    else
        mkdir -p "$HOME/Pictures/Wallpapers"
        git clone --depth 1 https://github.com/Totti786/Wallpapers.git "$HOME/Pictures/Wallpapers/Wallpapers.git"
    fi
    
    # Check if the operation was successful and report any errors
    if [[ $? -eq 0 ]]; then
        echo "Wallpapers updated successfully."
    else
        echo "Wallpapers update failed. Please check your internet connection and try again."
    fi
}

enable_autologin(){
	session_name=hyprland
	
	sed -i -e "s/Session=.*/Session=$session_name/g" /etc/sddm.conf.d/sddm.conf
	sed -i -e "s/User=.*/User=$(whoami)/g" /etc/sddm.conf.d/sddm.conf
	if [[ "$session_name" == "hyprland" ]]; then
		echo "exec-once = bash -c 'if [ "$(cut -d. -f1 /proc/uptime)" -lt 15 ]; then lockscreen; fi'" >> "$HOME/.config/hypr/custom.conf"
	fi
}

fixes(){
	sudo cp "$dir"/deps/fixes/quickshell.service /usr/lib/systemd/user/
	sudo cp "$dir"/deps/fixes/wayland-notif /usr/local/bin/
	sudo cp "$dir"/deps/fixes/org.notifications.quichshell.service /usr/share/dbus-1/services/
	sudo cp "$dir"/deps/fixes/org.geany.pkexec.policy /usr/share/polkit-1/actions
	sudo cp -r "$dir"/deps/fixes/libalpm/* /usr/share/libalpm/
	sudo chmod +x /usr/local/bin/wayland-notif
	sudo sh "$dir"/deps/fixes/libalpm/scripts/archlinux-hooks-extra fix-notifications
	sudo sh "$dir"/deps/fixes/libalpm/scripts/archlinux-hooks-extra fix-thunar
}

update(){
	## update dependencies and install new ones
	install_wayland
	progressBar "Updating... "
	ln -sfr "$HOME"/.themes/FlatColor "$HOME"/.themes/Dummy
	cp "$dir"/deps/.zprofile "$dir"/deps/.profile "$dir"/deps/.zshrc "$dir"/deps/.gtkrc-2.0 "$dir"/deps/.theme "$HOME"/
	## Move udpated scripts and configs
	cp -r "$dir"/bin/.local/ "$HOME"/
	rsync -a --delete \
	  --filter='protect gtk-3.0/bookmarks' \
	  --filter='protect xfce4/**' \
	  --filter='protect qt5ct/**' \
	  --filter='protect qt6ct/**' \
	  --filter='protect mpv/**' \
	  --filter='protect systemd/**' \
	  --filter='protect wpg/**' \
	  --filter='protect spicetify/**' \
	  --filter='protect copyq/**' \
	  --filter='protect Equicord/**' \
	  --filter='protect geany/**' \
	  --filter='protect fontconfig/**' \
	  --filter='protect pipewire/**' \
	  --exclude '/hypr/custom.conf' \
	  --exclude '/hypr/monitors.conf' \
	  "$dir"/cfg/* "$HOME"/.config/
	# Mark scripts as executable
	file_check
}

#---- TUI functions  ---------------------

Dialog="dialog"

menu(){
	if $Dialog --yesno "$1" 20 60 ;then	"$2" ;else "$3" ;fi
	}

progressBar(){
	for i in $(seq 1 100);do
	date +"$(printf $i $i)"
	sleep .0005
	done | "$Dialog" --gauge "$1" 20 60 0
	}

additionalPrograms(){
	if $Dialog --yesno "Do you want to select wich additional apps you want to install?\n
		Seleceting \"No\" will install all the additional apps" 20 60 ;then
	  	progs=$($Dialog --no-items --checklist "Choose the programs you want installed:"  20 60 12 \
		$(for app in ${extra[@]}; do echo "$app" off ;done) \
		2>&1 >/dev/tty) &&
		sudo pacman -Sy "$progs" --needed
	else
		sudo pacman -Sy ${extra[@]} --needed
	fi
	}

tools(){
	installOptions=$($Dialog --radiolist  "Choose one of the following options:"  15 60 4\
		fixes "Implement Various Fixes" off\
		checkrepo "Add Chaotic AUR repo" off\
		install_full "Install Dependencies" off\
		install_zsh "Zsh Configuration" off\
		install_sddm "SDDM Theme" off\
		install_firefox_theme "Firefox Theme" off\
		install_wpgtk "Generate color-schemes from wallpapers" off\
		2>&1 >/dev/tty)
	$installOptions
	}

install_menu(){
	local OPTIONS=(1 "Install X11 WMs (i3, BSPWM, Openbox)"
				   2 "Install Hyprland"
				   3 "Exit")
	local CHOICE=$($Dialog --clear \
	                --title "Install Script" \
	                --menu "Choose one of the following options:" \
	                10 80 4 \
	                "${OPTIONS[@]}" \
	                2>&1 >/dev/tty)
	case "$CHOICE" in
		1)
			x11_install
			;;
		2)
			wayland_install
			;;
		3)
			clear
			exit
			;;
	esac
	}

main(){
	local OPTIONS=(1 "Install"
	         2 "Install Additional Packages"
	         3 "Update"
	         4 "Download Wallpapers"
	         5 "Update Script"
	         6 "Tools"
	         7 "Exit")
	
	local CHOICE=$($Dialog --clear \
	                --title "Install Script" \
	                --menu "Choose one of the following options:" \
	                15 40 4 \
	                "${OPTIONS[@]}" \
	                2>&1 >/dev/tty)
	clear
	
	case "$CHOICE" in
		1)
			install_menu &&
			main
			;;
		2)
			additionalPrograms
			main
			;;
		3)
			git pull --recurse-submodules
			update
			main		
			;;
		4)
			wallpapers
			main
			;;
		5)
			git pull
			"$dir"/install.sh
			;;
		6)
			tools
			;;
		7)
			exit
			;;
	esac
	}

if [[ "$1" == "--update" ]]; then
	git pull --recurse-submodules
	"$0" "--actual-update"
elif [[ "$1" == "--actual-update" ]]; then
	update
elif [[ "$1" == "--wallpapers" ]]; then
	wallpapers
else
	if command -v "$Dialog" &> /dev/null; then 
		main
	else 
		sudo pacman -S "$Dialog" &&
		main
	fi
fi
