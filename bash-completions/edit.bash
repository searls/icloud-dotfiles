#!/usr/bin/env bash

# Bash completion for the 'edit' command
_edit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Get configuration from same environment variables
    local code_dir="${CODE_DIR:-$HOME/code}"
    local default_org="${DEFAULT_ORG:-searls}"

    # Handle flag completion
    case "$prev" in
        --editor|-e)
            # Complete editor names
            COMPREPLY=($(compgen -W "vim code code-insiders cursor claude" -- "$cur"))
            return 0
            ;;
    esac

    # If current word starts with a dash, complete flags
    if [[ "$cur" == -* ]]; then
        opts="--editor -e --help -h"
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
        return 0
    fi

    # Path completion logic
    local suggestions=()

    # Always include regular file/directory completion
    if [[ -n "$cur" ]]; then
        while IFS= read -r -d '' item; do
            # Strip leading ./
            item="${item#./}"
            suggestions+=("$item")
        done < <(compgen -f -- "$cur" | tr '\n' '\0')
    fi

    # If current word contains a slash, try org/repo completion
    if [[ "$cur" == */* ]]; then
        local org_part="${cur%/*}"
        local repo_part="${cur##*/}"

        # Complete against existing org directories in code_dir
        if [[ -d "$code_dir/$org_part" ]]; then
            for repo in "$code_dir/$org_part"/${repo_part}*; do
                if [[ -d "$repo" ]]; then
                    repo="${repo##*/}"  # Get basename
                    suggestions+=("$org_part/$repo")
                fi
            done
        fi
    else
        # No slash in current word - complete bare repo names

                # 1. Complete against directories in current directory
        for dir in ./${cur}*; do
            if [[ -d "$dir" ]]; then
                dir="${dir#./}"  # Remove ./
                suggestions+=("$dir")
            fi
        done

        # 2. Complete against directories in code_dir root
        if [[ -d "$code_dir" ]]; then
            for dir in "$code_dir"/${cur}*; do
                if [[ -d "$dir" ]]; then
                    dir="${dir##*/}"  # Get basename
                    suggestions+=("$dir")
                fi
            done
        fi

        # 3. Complete against repositories in default org
        if [[ -d "$code_dir/$default_org" ]]; then
            for repo in "$code_dir/$default_org"/${cur}*; do
                if [[ -d "$repo" ]]; then
                    repo="${repo##*/}"  # Get basename
                    suggestions+=("$repo")
                fi
            done
        fi

        # 4. Add org/repo completions for known orgs
        if [[ -d "$code_dir" ]]; then
            for org in "$code_dir"/${cur}*; do
                if [[ -d "$org" ]]; then
                    org="${org##*/}"  # Get basename
                    # Add the org with trailing slash for further completion
                    suggestions+=("$org/")
                fi
            done
        fi
    fi

    # Remove duplicates and sort
    local unique_suggestions=($(printf '%s\n' "${suggestions[@]}" | sort -u))

    # Generate completions
    COMPREPLY=($(compgen -W "${unique_suggestions[*]}" -- "$cur"))

    # If we have exactly one completion and it's a directory, add a trailing slash
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        local suggestion="${COMPREPLY[0]}"
        # Check if it's a directory (handle various path formats)
        if [[ -d "$suggestion" ]] || [[ -d "./$suggestion" ]] || [[ -d "$code_dir/$suggestion" ]] || [[ -d "$code_dir/$default_org/$suggestion" ]]; then
            # Don't add slash if it already ends with one
            if [[ "$suggestion" != */ ]]; then
                COMPREPLY[0]="$suggestion/"
            fi
        fi
    fi

    return 0
}

# Register the completion function
complete -F _edit_completion edit
