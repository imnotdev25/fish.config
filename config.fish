# Add this to ~/.config/fish/config.fish
# Auto-generate completions from --help for commands without completions

function __fish_auto_complete_from_help --description "Auto-complete from --help if no completions exist"
    set -l cmd $argv[1]
    set -l completion_dir ~/.config/fish/completions
    
    # Skip if completions already exist
    if test -f "$completion_dir/$cmd.fish"
        return 0
    end
    
    # Skip if command doesn't exist
    if not command -v $cmd &>/dev/null
        return 1
    end
    
    # Generate completions from --help
    set -l help_file /tmp/fish_help_$cmd.txt
    if $cmd --help &>$help_file 2>&1
        # Parse the help output and create completion
        mkdir -p $completion_dir
        __fish_parse_help_file $cmd $help_file > "$completion_dir/$cmd.fish"
        rm -f $help_file
    end
end

function __fish_parse_help_file --description "Parse help file and generate completions"
    set -l cmd $argv[1]
    set -l file $argv[2]
    
    echo "# Auto-generated from: $cmd --help"
    echo ""
    
    # Extract flags (both -x and --long-option)
    grep -oE '\s-([-a-zA-Z]+)' "$file" | sed 's/^\s*//' | sort -u | while read flag
        set -l desc (grep -A1 "^\s*$flag" "$file" | tail -1 | sed 's/^\s*//' | head -c 100)
        
        if string match -q -- '--*' $flag
            set -l name (string sub -s 3 $flag)
            echo "complete -c $cmd -l $name -d '$desc'"
        else if string length -q $flag; and test (string length $flag) -eq 2
            set -l char (string sub -s 2 $flag)
            echo "complete -c $cmd -s $char -d '$desc'"
        end
    end
end

# Hook into command-not-found to auto-generate completions
# This runs when you press Tab on a command without completions
function __fish_command_not_found_handler --on-variable fish_postexec
    # This is called after a command is executed
    # You could use this to lazily generate completions
end
