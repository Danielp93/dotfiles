#!/usr/bin/env bash
# Initial Linux Bootstrap Script

########################
# VARIABLES            #
########################
DEBIAN_FRONTEND=noninteractive
DEPENDENCIES=(
              git
	      jq
              unzip
	      make
	      cmake
	      g++
	      autogen
	      yodl
	      pkg-config
	      libtool
	      libtool-bin
	      ninja-build
	      gettext
	      python3-dev
	      python3-pip
	     )
SRC_DIR="/usr/src"
PROJECTMOUNT="/mnt/c/Users/danielp/Documents/projects"

BW_VERSION="1.9.1"
BW_EMAIL="Danielpot93@gmail.com"

TMUX_VERSION="3.1b"
NCURSES_VERSION="6.2"
LIBEVENT_VERSION="2.1.11"
NVIM_VERSION="stable"
ZSH_VERSION="5.8"

########################
# Pre-script Update    #
########################
echo -n "  [*] Installing dependencies..."
sudo apt-get -qq update
sudo apt-get -qq upgrade
sudo apt-get -qq install "${DEPENDENCIES[@]}" 
echo -e "\r  [+] Installing dependencies... SUCCESS"

########################
# Configure Bitwarden  #
########################
#Check if correct Bitwarden version is installed, if not, do so.
echo -e "  [*] Configuring Bitwarden Installation."
if [[ ! -x $(command -v bw) ]] || [[ $(bw -v) != $BW_VERSION ]]; then
    echo -e -n "    [*] Bitwarden not found, installing..."
    wget -q https://github.com/bitwarden/cli/releases/download/v$BW_VERSION/bw-linux-$BW_VERSION.zip -O /tmp/bw.zip \
            && sudo unzip -jqqo /tmp/bw.zip -d /usr/local/bin/ \
            && sudo chmod +x /usr/local/bin/bw
    echo -e "\r    [+] Bitwarden not found, installing... SUCCESS"
 fi
#Get valid Bitwarden Session
bw login --check || export BW_SESSION="$(bw login $BW_EMAIL --raw)"
bw unlock --check || export BW_SESSION="$(bw unlock --raw)"

########################
# Configure SSH Keys   #
########################
#Create .ssh Folder if it doesnt exist
#Download all Private Keys from Bitwarden to the SSH folder, then install, set permissions.
#Also generate public keys from them.
echo "  [*] Configuring SSH keys from Bitwarden."
	
  echo -n "    [*] Creating ~/.ssh directory..."
  mkdir -pm 700 ~/.ssh
  echo -e "\r    [+] Creating ~/.ssh directory: SUCCESS"

  echo -n "    [*] Fetching Private keys from Bitwarden and Creating public keys..."
  bw list items |\
	  jq -cr '.[] | select(.attachments?) | [.id, (.attachments[] | select(.fileName | endswith(".pub") | not) | .id)] | join(" ")' |\
          awk '{system("bw get attachment "$2" \
          			--itemid "$1" \
				--output ~/.ssh/" )}' &>/dev/null
  find ~/.ssh -type f -not \( -name "known_hosts" -o \
  			-name "authorized_key" -o \
			-name "config" -o \
		       	-name "*.pub" \) \
				-exec chmod 600 {} \;\
          			-exec sh -c "ssh-keygen -y -f {} > {}.pub" \;
  echo -e "\r    [+] Fetching Private keys from Bitwarden and Creating public keys... SUCCESS"
  
  ( [ -f ~/.ssh/config ] || touch ~/.ssh/config ) && chmod 0600 ~/.ssh/config
  if ! grep -q "Host github.com" ~/.ssh/config; then
    if [ -f ~/.ssh/GithubPersonal ]; then
      echo -n "    [*] Adding git user to ssh_config..."
        sudo tee -a ~/.ssh/config &>/dev/null <<-EOF
	#Added by bootstrap.sh
	Host github.com
	    User Git
	    IdentityFile ~/.ssh/GithubPersonal
	EOF

      echo -e "\r    [+] Adding git user to SSH config: SUCCESS"
    fi
  fi
echo "  [+] Configured SSH keys from Bitwarden successfully."

########################
# Setup Dotfiles Repo  #
########################
echo "  [*] Configuring Dotfiles Repo."
echo -n "    [*] Adding github Public key to known hosts..."
ssh-keyscan github.com &> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
echo -e "\r    [+] Added github Public key to known hosts... SUCCESS"
echo -n "    [*] Cloning .dotfiles Repo and Configuring 'config ...' alias..."
if [  -d ~/.cfg ]; then
  mv -f ~/.cfg /tmp/.cfg-$(date +%m%d%Y)
fi

echo ".cfg" > ~/.gitignore
git clone --bare git@github.com:Danielp93/dotfiles.git ~/.cfg &> /dev/null
if [ $? -eq 0 ]; then
  config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
  # Checkout config
  $config checkout &>/dev/null
  [ $? = 0 ] || config checkout 2>&1 | grep -E "^\s+." | awk {'print $1'} | xargs -I{} mv {} /tmp/{}
  $config checkout
  $config config --local status.showUntrackedFiles no
  [[ -f $HOME/.profile ]] && source $HOME/.profile
  echo -e "\r    [+] Cloning .dotfiles Repo and Configuring 'config ...' alias... SUCCESS"
else
  echo -e "\r    [-] Cloning .dotfiles Repo and Configuring 'config ...' alias... FAILED" 
  return 1
fi
echo "  [+] Configured Dotfiles Repo successfully."
########################
#  ZSH, TMUX & NEOVIM  #
#######################
echo "  [*] Downloading, building and installing ZSH, TMUX and NEOVIM."
  echo "    [+] Resolving Dependencies"
   #Installing Dependency: Ncurses
    echo -n "      [*] Ncurses: Downloading/Extracting..."
      wget -qO- http://ftp.gnu.org/pub/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz |\
		sudo tar zxf - -C $SRC_DIR
    echo -e "\r      [+] Ncurses: Downloading/Extracting... SUCCESS"
    echo -n "      [*] Ncurses: Building/Installing... "
      cd $SRC_DIR/ncurses-$NCURSES_VERSION
      sudo ./configure CXXFLAGS="-fPIC" CFLAGS="-fPIC" &>/dev/null
      sudo make -j8 &>/dev/null
      sudo make install &>/dev/null
      cd --
    echo -e "\r      [+] Ncurses: Building/Installing... SUCCESS"
    #Installing Dependency: Libevent
    echo -n "      [*] Libevent: Downloading/Extracting..."
      wget -qO- https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VERSION-stable/libevent-$LIBEVENT_VERSION-stable.tar.gz |\
        	sudo tar zxf - -C $SRC_DIR
    echo -e "\r      [+] Libevent: Downloading/Extracting... SUCCESS"
    echo -n "      [*] Libevent: Building/Installing... "
      cd $SRC_DIR/libevent-$LIBEVENT_VERSION-stable 
      sudo ./autogen.sh &>/dev/null
      sudo ./configure &>/dev/null
      sudo make -j8 &>/dev/null
      sudo make install &>/dev/null
      cd --
    echo -e "\r      [+] Libevent: Building/Installing... SUCCESS"
  echo "    [+] Dependencies Resolved"
  #Installing ZSH
  echo "    [*] ZSH:"  
    echo -n "      [*] Downloading/extracting..."
      wget -qO- https://github.com/zsh-users/zsh/archive/zsh-$ZSH_VERSION.tar.gz |\
		sudo tar zxf - -C $SRC_DIR
    echo -e "\r      [+] Downloading/extracting... SUCCESS"
    echo -n "      [*] Installing... "
      cd $SRC_DIR/zsh-zsh-$ZSH_VERSION
      sudo ./Util/preconfig &>/dev/null
      sudo ./configure &>/dev/null
      sudo make -j8 &>/dev/null
      sudo make install &>/dev/null
      cd --
      
    echo -e "\r      [+] Installing... SUCCESS"
  #Installing TMUX
  echo "    [*] TMUX:"
    echo -n "      [*] Downloading/extracting..."
      wget -qO- https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz |\
		sudo tar zxf - -C $SRC_DIR
    echo -e "\r      [+] Downloading/extracting... SUCCESS"
    echo -n "      [*] Installing... "
      cd $SRC_DIR/tmux-$TMUX_VERSION
      sudo ./configure &>/dev/null
      sudo make -j8 &>/dev/null
      sudo make install &>/dev/null
      cd --
    echo -e "\r      [+] Installing... SUCCESS"
  #Installing NVIM
  echo "    [*] NEOVIM:"
    echo -n "      [*] Downloading/extracting..."
      sudo git clone https://github.com/neovim/neovim.git $SRC_DIR/neovim &>/dev/null
    echo -e "\r      [+] Downloading/extracting... SUCCESS"
    echo -n "      [*] Installing... "
      cd $SRC_DIR/neovim
      sudo checkout tags/$NVIM_VERSION &>/dev/null
      sudo make &>/dev/null
      sudo make install &>/dev/null
      cd --
      
      NVIM_PATH=/usr/local/bin/nvim 
      sudo update-alternatives  --quiet --install /usr/bin/ex ex $NVIM_PATH 110
      sudo update-alternatives  --quiet --install /usr/bin/vi vi $NVIM_PATH 110
      sudo update-alternatives  --quiet --install /usr/bin/view view $NVIM_PATH 110
      sudo update-alternatives  --quiet --install /usr/bin/vim vim $NVIM_PATH 110
      sudo update-alternatives  --quiet --install /usr/bin/vimdiff vimdiff $NVIM_PATH 110

    echo -e "\r      [+] Installing... SUCCESS" 
echo "  [+] Done installing ZSH, TMUX and NVIM"
echo "  [*] WSL only installation steps"
echo -n "    [*] Check if running WSL..."
  if [[ $(grep Microsoft /proc/version) ]]; then
    echo -e "\e    [+] Check if running WSL...SUCCESS"
    echo -n "    [*] Symlinking ~/projects to $PROJECTMOUNT"
    [ -d $PROJECTMOUNT ] && ln -s $PROJECTMOUNT $HOME/projects
    echo -e "\r    [+] Symlinking ~/projects to $PROJECTMOUNT"
  fi
echo "  [+] WSL only installation steps done" 
