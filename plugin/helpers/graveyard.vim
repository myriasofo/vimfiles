
finish

" Might use again
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

    " Settings for python-mode
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

" Totally useless
    " Figuring out ctrlp options
        " Do not clear filenames cache, to improve CtrlP startup
        " For ctrlp: don't clear cache (to manually clear, <f5>)
        "let g:ctrlp_clear_cache_on_exit = 0

        let g:ctrlp_user_command = 'dir %s /-n /b /s /a-d'
        "let g:ctrlp_user_command = 'dir %s /-n /b /ad'
        " Set delay to prevent extra search
        "let g:ctrlp_lazy_update = 350
        "let g:ctrlp_use_caching = 0

        " Set no file limit, we are building a big project
        let g:ctrlp_max_files = 0

        " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
        "let g:ctrlp_user_command = 'ag -l --nocolor -g "" %s'
        " ag is fast enough that CtrlP doesn't need to cache

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


    " Manage dups for MBE fname tails
        "GIVEN
        let bufs = [1,7,3,9,10,2, 4]
        let g:correspondence = {
            \'1':  'C:\f2',
            \'7':  'C:\g\a\f',
            \'3':  'C:\h\b\f',
            \'9':  'C:\i\c\b\f',
            \'10': 'C:\f3',
            \'2':  'C:\j\d\b\f',
            \'4':  'C:\k\e\d\b\f',
        \}
        "WANT
        let want = [ [1,""], [7,"a"], [3, "h" ], [9, "c"], [10, ""], [2, "j"], [4,"e"]]

        "let bufs = [7,3]
        "let g:correspondence = {
        "    \'7':  'C:\a\f',
        "    \'3':  'C:\b\f',
        "\}
        "let want = [ [7,"a"], [3, "b" ]]


        fun! Manage(bufNums)
            " Assume fnameArr has *full path* (not tail or shortened path)
            let dct = {}
            for bufNum in a:bufNums
                let fullPath = g:correspondence[bufNum]

                let tail = fnamemodify(fullPath, ':t')
                if has_key(dct, tail)
                    call add(dct[tail], bufNum)
                else
                    let dct[tail] = [bufNum]
                endif
            endfor
            echo dct

            for tail in keys(dct)
                let bufNums = dct[tail]
                if len(bufNums) > 1
                    call s:manage(bufNums)
                endif
            endfor
        endfun

        " NOTE: only use bufNums and finished
        fun! s:manage(bufNums)
            echo 'yes' a:bufNums

            " Race!
            let finished = []
            let level = -1
            "while len(a:bufNums) > 0
            "while level > -5
            while len(a:bufNums) > 0
                let level -= 1
                call s:manage2(a:bufNums, level, finished)
            endwhile

            echo finished
            "return finished
        endfun

        fun! s:manage2(bufNums, level, finished)
            " Are there any diff parents in this level?
            let parents = {}
            for bufNum in a:bufNums
                let splitPath = split(g:correspondence[bufNum], '\')
                "echo 'splitPath:' splitPath
                let parent = splitPath[a:level]
                "echo 'parent:' parent

                if has_key(parents, parent)
                    call add(parents[parent], bufNum)
                else
                    let parents[parent] = [bufNum]
                endif
            endfor
            "echo 'parents' parents

            " TODO: any are not dups?
            for parentName in keys(parents)
                let bufNums = parents[parentName]
                if(len(bufNums) == 1)
                    let bufNum = bufNums[0]
                    echo 'bufNum' bufNum
                    call add(a:finished, [bufNum, parentName])
                    call remove(a:bufNums, index(bufNums, bufNum))
                endif
            endfor
        endfun

