function _fifc_parse_complist -d "Parse fish completion list and set the tabstop accordingly"
    set tabstop (math (cat $_fifc_complist_path | awk '{print $1}' | wc -L) + 4)
    if test $tabstop -gt $_fifc_tabstop
        set _fifc_tabstop $tabstop
    end

    cat $_fifc_complist_path \
        | string unescape \
        | uniq
end
