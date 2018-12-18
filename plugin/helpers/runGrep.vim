

" Main
function! RunGrep(...)
    let query = s:formatQuery(a:000)

    let executed = s:executeGrep(query)

    if executed
        call s:setupGrepWindow(query)
    endi
endfunction


" Process query
function! s:formatQuery(arguments)
    if len(a:arguments) == 0
        return s:getQueryFromLastSearch()
    endif

    let query = a:arguments[0]
    call s:highlightQuery(query)
    return query
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

function! s:highlightQuery(input)
    let @/ = matchstr(a:input, "\\v(-)\@<!(\<)\@<=\\w+|['\"]\\zs.{-}\\ze['\"]")
endfunction


" Execute query and display
function! s:setupGrepWindow(query)
    " Show highlight
    set hlsearch
    call feedkeys(":let &hlsearch=1 \| echo \<CR>", "n") "might do nothing
    "set foldlevel=99 "unnecessary?
    redraw!

    " Prep quickfix window
    let prevWin = win_getid()
    botright copen
    if &filetype == "qf"
        call setwinvar(0, "&statusline", '  QUERY: ['.a:query.'] %5l/%L')
        set modifiable
        redraw!
    endif
    call win_gotoid(prevWin)
endfunction

function! s:executeGrep(query)
    echom 'GREP PRG: '.&grepprg
    echom 'GREP QUERY: '.a:query

    try
        let cmd = &grepprg.' '.a:query

        " the command 'cgetexpr' is nice bc doesnt auto open any wins
        cgetexpr system(cmd)
        return 1
    catch
        echom "Invalid query: ".a:query
        return 0
    endtry
endfunction


command! -nargs=? Indexer call RunGrep(<f-args>)
