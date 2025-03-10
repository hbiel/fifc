function _fifc
    set -l result
    set -gx _fifc_extract_regex
    set -gx _fifc_complist_path (string join '' (mktemp) "_fifc")
    set -gx _fifc_custom_fzf_opts
    set -gx fifc_extracted
    set -gx fifc_commandline
    set -gx fifc_token (commandline --current-token)
    set -gx fifc_query "$fifc_token"
    set -gx _fifc_tabstop 20
    # Get commandline buffer
    if test "$argv" = ""
        set fifc_commandline (commandline --cut-at-cursor)
    else
        set fifc_commandline $argv
    end

    if _fifc_test_version "$FISH_VERSION" -ge "3.4"
        set complete_opts --escape
    end

    complete -C $complete_opts -- "$fifc_commandline" | string split '\n' >$_fifc_complist_path

    set -gx fifc_group (_fifc_completion_group)
    set _fifc_extract_regex (_fifc_action extract)
    set source_cmd (_fifc_action source)

    set fifc_fzf_query (string trim --chars '\'' -- "$fifc_fzf_query")

    set -l fzf_cmd "
        fzf \
            -d \t \
            --exact \
            --tiebreak=length \
            --select-1 \
            --exit-0 \
            --ansi \
            --tabstop=$_fifc_tabstop \
            --multi \
            --reverse \
            --header '$header' \
            --preview '_fifc_action preview {} {q}' \
            --bind='$fifc_open_keybinding:execute(_fifc_action open {} {q} &> /dev/tty)' \
            --query '$fifc_query' \
            $_fifc_custom_fzf_opts"

    set -l cmd (string join -- " | " $source_cmd $fzf_cmd)
    # We use eval hack because wrapping source command
    # inside a function cause some delay before fzf to show up
    eval $cmd | while read -l token
        # string escape will escape '~' if present (at the begenning of path).
        # so we need to exclude it from escaping
        if string match --quiet '~*' -- $token
            set -a result (string join -- "" "~" (string sub --start 2 -- $token | string escape))
        else
            set -a result (string escape --no-quoted -- $token)
        end
        # Perform extraction if needed
        if test -n "$_fifc_extract_regex"
            set result[-1] (string match --regex --groups-only -- "$_fifc_extract_regex" "$token")[1]
        end
    end

    # Add space trailing space only if:
    # - there is no trailing space already present
    # - Result is not a directory
    # We need to unescape $result for directory test as we escaped it before
    if test (count $result) -eq 1; and not test -d (string unescape -- $result[1])
        set -l buffer (string split -- "$fifc_commandline" (commandline -b))
        if not string match -- ' *' "$buffer[2]"
            set -a result ''
        end
    end

    if test -n "$result"
        commandline --replace --current-token -- (string join -- ' ' $result)
    end

    commandline --function repaint

    rm $_fifc_complist_path
    # Clean state
    set -e _fifc_extract_regex
    set -e _fifc_custom_fzf_opts
    set -e _fifc_complist_path
    set -e fifc_token
    set -e fifc_group
    set -e fifc_extracted
    set -e fifc_candidate
    set -e fifc_commandline
    set -e fifc_query
end
