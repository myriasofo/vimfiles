
" Main
function! RunGrep(...)
    let query = s:formatQuery(a:000)

    call s:configureGrepCommand()

    let executed = s:executeGrep(query)

    if executed
        call s:setupGrepWindow(query)
    endi
endfunction


" Process query
function! s:formatQuery(arguments)
    let [query, queryParams] = len(a:arguments) == 1 ?
        \s:extractQuery(a:arguments[0]) :
        \s:getQueryFromLastSearch()

    let query = s:confirmQueryHasQuotes(query)

    return query . ' ' . join(queryParams, ' ')
endfunction

function! s:extractQuery(input)
    let query = a:input
    let queryParams = []

    for param in ['-s', '-w', '-Q']
        let index = s:findParam(query, param)
        if index != -1
            let query = strpart(query, 0, index) . strpart(query, index+len(param)+1)
            call add(queryParams, param)
        endif
    endfor

    let query = StripWhitespace(query)
    call s:setHighlight(query, queryParams)

    return [query, queryParams]
endfunction

function! s:getQueryFromLastSearch()
    let query = getreg('/')

    if query[0:1] == '\<' && query[-2:-1] == '\>' 
        return [query[2:-3], ['-w', '-s']]

    elseif query[0:1] == '\c'
        return [query[2:], ['-i']]

    else
        return [query, ['-s']]
    endif
endfunction

function! s:findParam(str, param)
    if a:str[:2] == a:param.' ' 
        return 0
    endif

    return match(a:str, ' '.a:param)
endfunction

function! s:setHighlight(query, queryParams)
    let query = a:query
    if (query[0] == '"' && query[-1:] == '"') || (query[0] == "'" && query[-1:] == "'") 
        let query = query[1:-2]
    endif

    if index(a:queryParams, '-s') == -1
        let @/ = '\c'.query
    else
        let @/ = query
    end
endfunction

function! s:confirmQueryHasQuotes(query)
    let query = a:query

    if query[0] != '"' && query[0] != "'"
        let query = '"' . query
    endif

    if query[-1:] != '"' && query[-1:] != "'"
        let query .= '"'
    endif

    return query
endfunction


" Execute query and display
function! s:configureGrepCommand()
    if executable('ag')
        let &grepprg = 'ag -i --nogroup --nocolor --hidden' . s:getIgnoredDirs()
    elseif g:os == 'windows'
        let &grepprg = 'findstr /n /s'
    endif
endfunction

function! s:getIgnoredDirs()
    let ignored_dirs = g:my_grep_ignored_core

    let current_dir = fnamemodify(getcwd(), ':~')
    if has_key(g:my_grep_ignored_dirs, current_dir)
        let ignored_dirs += g:my_grep_ignored_dirs[current_dir]
    endif

    let ignore_dirs_string = ''
    for ignore_dir in ignored_dirs
        let ignore_dirs_string .= ' --ignore-dir ' . ignore_dir
    endfor
    return ignore_dirs_string
endfunction

function! s:executeGrep(query)
    try
        let cmd = 'silent grep '.a:query.' *'
        echom 'GREP PRG: '.&grepprg
        echom 'GREP: '.cmd
        exe cmd
        return 1
    catch
        echom "Invalid query: ".a:query
        return 0
    endtry
endfunction

function! s:setupGrepWindow(query)
    " Format result
    set hlsearch
    set foldlevel=99
    redraw!

    " Prep quickfix window
    copen
    if &filetype == "qf"
        call setwinvar(0, "&statusline", '  Found '.len(getqflist())." for [".a:query."]")
        "set ffs=dos
        "silent g/\\\$/s///
        redraw!
    endif
endfunction


command! -nargs=? Indexer call RunGrep(<f-args>)
