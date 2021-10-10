# Homebrew Settings
export PATH=/usr/local/sbin:$PATH	        				# linking Homebrew
CACHED_PATH=$(echo $PATH)									# cach PATH environment variable
export PATH=/usr/local/anaconda3/bin:"$PATH"				# linking anaconda

# fixed the issue with extra configs from Anaconda		
brew() {
	export PATH=$CACHED_PATH								# use cached PATH environment variable
	command brew "$@"
	export PATH=/usr/local/anaconda3/bin:"$CACHED_PATH"		# linking anaconda
}

# Export JavaHome for Android Studio
export JAVA_HOME=$(/usr/libexec/java_home)

# Aliases
alias wd="cd ~/Developer"
alias refresh="source ~/.zshrc"

# ZSH Autocomplete Plugin
source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# ZSH Syntax Highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ZSH Auto Suggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ZSH Key Bindings
# bindkey '\e[A' history-beginning-search-backward
# bindkey '\e[B' history-beginning-search-forward
bindkey '^[[1;2C' history-beginning-search-backward # Bind to Shift + Left Arrow
bindkey '^[[1;2D' history-beginning-search-forward  # Bind to Shift + Right Arrow

# Kubernetes Completion
autoload -Uz compinit
compinit

source <(kubectl completion zsh)

# Git info

function len() {
	echo -n $1 | wc -m
}

function display_bg() {
	text=$1
	color=$2

	echo " %K{$color} ${text} %k "
}

function git_status() {
	is_clean=$(git status 2> /dev/null | grep "nothing to commit")
	if [[ $is_clean ]];
	then
		echo ✓
	else
		echo ✗
	fi
}

function git_commits() {
	repo_name=$(git config --local remote.origin.url 2> /dev/null | grep -o -E "[^/]*.git$" | sed 's/.git//g')

	if [[ $repo_name == "" ]]
	then
		echo "[local]"
	else
		commits=($(git status 2> /dev/null | grep "different commits" | grep -o -E '\d+' | tr '\n' ' '))
		push_commits=${commits[1]:-$(git status 2> /dev/null | grep ahead | grep commit | grep -o -E '\d+')}
		pull_commits=${commits[2]:-$(git status 2> /dev/null | grep behind | grep commit | grep -o -E '\d+')}
		echo "⇡ ${push_commits:-0} ⇣ ${pull_commits:-0} [$repo_name]"
	fi
}

function display_branch() {
	branch_name=$1
	bg_color=$2
	fg_color=$3

	commits_offset_base=7
	branch_name_limit_base=30

	commits=$(git_commits)
	commits_offset=$(($(len $commits) - $commits_offset_base))
	branch_name_limit=$(($branch_name_limit_base - $commits_offset))

	read -r branch_name_length <<< $(len $branch_name)
	
	if [[ "$branch_name_length" -gt "$branch_name_limit" ]];
	then
		branch_name="${branch_name:0:$branch_name_limit}..."
	fi

	if [[ $fg_color ]];
	then
		branch_name="%F{$fg_color}$branch_name%f"
	fi

	display_bg "🐙 $branch_name $(git_status) $(git_commits)" $bg_color
}

# Find and set branch name var if in git repository.
function git_branch_name()
{
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="refs/heads/"} {print $NF}')
  if [[ $branch == "" ]];
  then
	is_head_detached=$(git status 2> /dev/null | grep "HEAD detached")
	if [[ $is_head_detached ]];
	then
		display_branch "HEAD detached" green red
	else
		echo ' '
	fi 
  else
	IFS=/ read -rA parsed_branch <<< "$branch"
	read -r length <<< ${#parsed_branch[@]}
	read -r branch_type <<< ${parsed_branch[1]}
	read -r branch_name <<< ${parsed_branch[-1]}

	if [[ $length == 1 ]];
	then
		if [[ $branch == main || $branch == master ]];
		then
			display_branch $branch green
		else
			display_branch $branch cyan
		fi
	else
		read -r is_feature <<< $(echo "$branch_type" | grep 'feature')
		read -r is_release <<< $(echo "$branch_type" | grep 'release')
		read -r is_bugfix <<< $(echo "$branch_type" | grep 'bug')
		read -r is_hotfix <<< $(echo "$branch_type" | grep 'hotfix')

		if [[ $is_feature ]];
		then
			display_branch $branch_name cyan
		elif [[ $is_release ]];
		then
			display_branch $branch_name blue
		elif [[ $is_bugfix ]];
		then
			display_branch $branch_name yellow
		elif [[ $is_hotfix ]];
		then
			display_branch $branch_name red
		else
			display_branch $branch_name cyan
		fi
	fi

  fi
}

# Enable substitution in the prompt.
setopt prompt_subst

# Custom terminal prompt

export PS1='⭐ %F{034}@%n%f → 📁 %1~$(git_branch_name)%F{green}▶ %f'
