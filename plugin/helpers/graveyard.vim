
finish

fun! TestFont(val)
    if has('unix') "For linux mint, 1920x1680
        if a:val == 1
            let &guifont = "Consolas 12"
            "let &guifont = "Consolas 15"
            set linespace=5
        elseif a:val == 2
            let &guifont = "Inconsolata Medium 13"
            set linespace=1
        else
            let &guifont = "Source Code Pro Regular 13" 
            "let &guifont = "Source Code Pro Regular 15"
            set linespace=0
        endif

    else "For win10 (50% scaling)
        if a:val == 1
            let &guifont = "Source_Code_Pro:h9"
            "let &guifont = "Source_Code_Pro:h10"
        else
            let &guifont = "Consolas:h9"
            "let &guifont = "Consolas:h11"
        endif
    endif

endfun

" Figuring out ctrlp options
    " Do not clear filenames cache, to improve CtrlP startup
    " For ctrlp: don't clear cache (to manually clear, <f5>)
    "let g:ctrlp_clear_cache_on_exit = 0
    let g:ctrlp_working_path_mode = 0
    let g:ctrlp_show_hidden = 1
    let g:ctrlp_user_command = 'dir %s /-n /b /s /a-d'
    "let g:ctrlp_user_command = 'dir %s /-n /b /ad'
    let g:ctrlp_custom_ignore = {
        \ 'dir': '\v(
            \Dropbox\\Art
            \|projects\\CMB
            \|vimfiles\\backup|vimfiles\\undofiles|vimfiles\\session
            \|Archives\\documentation|reinstallation|Archives\\static|\.git
            \|CS\\books_algorithms
            \|CVS
            \|Tasks\\[discard
        \)'
    \ }
    let g:ctrlp_prompt_mappings = {
        \ 'PrtDeleteWord()': ['<c-bs>'],
        \ }

    " Set delay to prevent extra search
    "let g:ctrlp_lazy_update = 350
    "let g:ctrlp_use_caching = 0

    " Set no file limit, we are building a big project
    let g:ctrlp_max_files = 0

    " Trying to use pymatcher
        if has('python')
            let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
        else
            "echom 'pymatcher requires python'
        endif

" Trying out ctrlspace (concl: doesn't improve on ctrlp)
    "let g:CtrlSpaceSymbols = { "File": "░", "CTab": "▌", "Tabs": "▓" }
    "let g:CtrlSpaceUseUnicode = 0

    " use ag  (something lelse?)
    "if executable("ag")
    "    let g:CtrlSpaceGlobCommand = 'ag -l --nocolor -g ""'
    "endif

    " <b> to add proj to bookmark
    " <o> to open files
    " <w> to save worspace

    " <h> for home - see all buffers

    " CtrlSpaceAddProjectRoot -
    " My maps are interferring w ctrlspace's maps (annoying)

" For python (in progress)
    " For python­mode plugin
    "let g:pymode = 0
    "let g:pymode_run = 0
    "let g:pymode_breakpoint = 0
    "let g:pymode_folding = 0
    "let g:pymode_trim_whitespaces = 0
    "let g:pymode_options = 0
    "let g:pymode_lint = 0
    "let g:pymode_rope = 0
    "let g:pymode_motion = 0
    "let g:pymode_virtualenv = 0
    "let g:pymode_doc = 1
    "let g:pymode_doc_bind = 'K'
    "" pymode breakpoint? cool
    """ pymodelint/pep8/pyflakes

fun! TestSignColumn()
    sign define tester text=| texthl=Folded
    exe ":sign place 2 line=5 name=tester buffer=" . winbufnr(0)

    "sign define piet text=>> texthl=Search
    "hi SignColumn
    "sign place 2
    "sign place 2 line=23 name=tester buffer=winbufnr(0)
    "sign unplace 2
    hi Folded guibg=black guifg=white
    hi FoldColumn guibg=blue guifg=white
    "omg what is foldcolumn?
    set foldcolumn=1
endfun

" Options for IndentGuides
    "let g:indent_guides_enable_on_vim_startup = 1
    "let g:indent_guides_auto_colors = 0
    "hi IndentGuidesOdd  guibg=bg
    "hi IndentGuidesEven guibg=#214651
    "
    "hi IndentGuidesOdd  guibg=#214651
    "hi IndentGuidesEven guibg=bg
    "hi IndentGuidesEven guibg=#657b83
    "hi IndentGuidesEven guibg=#0c3540
    "hi IndentGuidesEven guibg=#07313c
    "let g:indent_guides_color_change_percent = 7

" Save/load fold views
    if !exists("g:loadOnce_temp")
        let g:loadOnce_temp = 1
        " Discovering au more
            "au BufNewFile * call PrintFileInfo('new file')
            "au BufNew * call PrintFileInfo('buf new')
            "au BufAdd * call PrintFileInfo('buf add')
            "au BufRead * call PrintFileInfo('buf read')
            "au BufHidden * call PrintFileInfo('buf hidden')
            "au BufUnload * call PrintFileInfo('buf unload')
            "au FileType * call PrintFileInfo('filetype')

            fun! PrintFileInfo(event)
                echom a:event."| file:".expand('%')
                echom "ft:".&ft."| buftype:".&buftype
                echom "curr win: ".winnr()
                echom "buf # in curr win: ".winbufnr(winnr())
            endfun
            "let winOf1 = winbufnr(1)
            "let exists1 = bufnr(1)

        " How to save folds reliably?
            set viewoptions =folds
            fun! SaveFold()
                "if expand('%') != '' && &buftype!~'nofile'
                if &buftype != 'help' && &buftype != 'nofile'
                    if bufnr(1) == -1
                        mkview
                        echom 'actually saved folds'
                    endif
                endif
            endfun
            fun! SaveFoldAll()
                for i in range(bufnr('$'))
                    if &buftype != 'help' && &buftype != 'nofile'
                        exe 'b'.i
                        mkview
                    endif
                endfor
            endfun
            fun! LoadFold()
                "echom "trying to load fold"
                if &buftype != 'help' && &buftype != 'nofile'
                    if bufnr(1) == -1
                        loadview
                        echom 'actually loaded folds'
                        "let g:accum .= &ft.' '
                    endif
                endif
            endfun
    endif


" Setup Indent lines
    "au BufRead * call DrawIndentLine() "syntax match REALLY slows down big files

    " NOTE - this must go *after* other syntax hl
    "set conceallevel=2
    "set concealcursor=nic

    " about same colors as text
    "highlight Conceal guibg=NONE guifg=#586e75

    " nice
    if &background == "dark"
        highlight Conceal guibg=NONE guifg=#214651
    else
        highlight Conceal guibg=NONE guifg=gray
    endif

    " too light
    "highlight Conceal guibg=NONE guifg=0c3540

    let g:indentLine_char = '¦'
    "let g:indentLine_char='│'
    "let g:indentLine_char='░'
    "let g:indentLine_char='▓'
    "let g:indentLine_char='▒'
    "let g:indentLine_char='▌'
    let g:indentLine_maxInd = 10

    fun! DrawIndentLine()
        if &filetype == 'todo'
            return
        endif

        let space = &shiftwidth
        for i in range(space+1, space * g:indentLine_maxInd + 1, space)
            execute 'syntax match IndentLine /\%(^\s\+\)\@<=\%'.i.'v / containedin=ALL conceal cchar='.g:indentLine_char
        endfor
    endfun

" Indents after newlines
    "au FileType * call IndentingForNewLines()
    "fun! IndentingForNewLines()
    "    if &filetype == 'todo'
    "        setlocal autoindent
    "    else
    "        setlocal autoindent
    "        "setlocal cindent "Problem is that ONLY for C -> so weird special cases
    "        "setlocal cinkeys-=0#
    "    endif
    "endfun

" Trying for netrw
    "au FileType netrw call s:setup_vinegar()
    "au FileType netrw call SetupNetrw()
    "au BufRead * call SetupNetrw()
    "au BufNewFile * call SetupNetrw()
    "fun! SetupNetrw()
    "    echo 'any file'
    "    if &filetype == 'netrw'
    "        echom 'setup netrw!'
    "        "nnoremap <silent> s :<c-u>call ScoutKey()<cr>
    "    endif
    "endfun
