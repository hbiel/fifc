function _fifc_source_files -d "Return a command to recursively find files"
    set -l path (_fifc_path_to_complete | string escape)

    set -l potential_path (string match -r -g '(.*\/)?(?:.*)' $path)
    set -l potential_query (string match -r -g '(?:.*\/)?(.*)' $path)
    set -l hidden (string match ".*" "$potential_query")

    if test -d $path -a -z "$hidden"
        set -e fifc_query
    else
        set path $potential_path
        set fifc_query $potential_query
    end

    if type -q fd
        set -l fd_opts "--color=always" $fifc_fd_opts

        test -n "$hidden" && set -a fd_opts "--hidden"
        if test "$path" = "$PWD/"
            _fifc_test_version (fd --version) -ge "8.3.0" && set -a fd_opts --strip-cwd-prefix
        else if test -n "$path" 
            set -a fd_opts "--" "$path"
        end

        echo "fd . $fd_opts"
    else if test -n "$hidden"
        # Use sed to strip cwd prefix
        echo "find . $path ! -path . -print $fifc_find_opts 2>/dev/null | sed 's|^\./||'"
    else
        # Exclude hidden directories
        echo "find . $path ! -path . ! -path '*/.*' -print $fifc_find_opts 2>/dev/null | sed 's|^\./||'"
    end
end
