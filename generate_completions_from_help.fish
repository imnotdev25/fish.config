#!/usr/bin/env fish
# Auto-generate Fish shell completions from --help or -h output
# Usage: fish generate_help_completions.fish <command_name>
# cp generate_completions_from_help.fish ~/.config/fish/functions/
# chmod +x ~/.config/fish/functions/generate_completions_from_help.fish
# source ~/.config/fish/config.fish
# generate_completions_from_help curl
# generate_completions_from_help wget
# generate_completions_from_help git
# generate_completions_batch curl wget tar rsync ffmpeg 
# generate_completions_from_help -f curl Force Regeneration Overwrite Existing
# Fish Version v4.0.2


function generate_help_completions --description "Generate Fish completions from --help output"
    set -l command $argv[1]
    
    if test -z "$command"
        echo "Usage: generate_help_completions <command_name>"
        return 1
    end
    
    # Try to get help output
    set -l help_output
    if $command --help &>/dev/null
        set help_output ($command --help 2>&1)
    else if $command -h &>/dev/null
        set help_output ($command -h 2>&1)
    else
        echo "Error: Could not get help from '$command'"
        return 1
    end
    
    # Parse flags (lines starting with - or --)
    set -l flags (echo "$help_output" | grep -oE '^\s*(-[a-zA-Z]|--[a-zA-Z0-9-]+)' | sed 's/^\s*//' | sort -u)
    
    # Generate completion file
    set -l completion_file ~/.config/fish/completions/$command.fish
    mkdir -p (dirname $completion_file)
    
    echo "# Auto-generated completions for $command" > $completion_file
    echo "# Generated from: $command --help" >> $completion_file
    echo "" >> $completion_file
    
    for flag in $flags
        # Try to extract description from help output
        set -l description (echo "$help_output" | grep -A 1 "^\s*$flag" | tail -1 | sed 's/^\s*//' | head -c 100)
        
        echo "complete -c $command -n '__fish_seen_subcommand_from' -f" >> $completion_file
        
        if string match -q -- '--*' $flag
            # Long option
            set -l flag_name (string sub -s 3 $flag)
            echo "complete -c $command -l $flag_name -d '$description'" >> $completion_file
        else
            # Short option
            set -l flag_char (string sub -s 2 $flag)
            echo "complete -c $command -s $flag_char -d '$description'" >> $completion_file
        end
    end
    
    echo "✓ Completions generated: $completion_file"
end

# Run if script is executed directly
if test (basename (status filename)) = "generate_help_completions.fish"
    generate_help_completions $argv
end
