; ==============================================================================
; [ MODULE: DYNAMIC CHEATSHEET PARSER & GUI ]
; ==============================================================================

global cheatGui := "" ; Promoted to global so the background Hotkey can destroy it

ShowCheatSheet() {
    global cheatGui
    
    if (cheatGui) {
        if DllCall("IsWindowVisible", "Ptr", cheatGui.Hwnd) {
            cheatGui.Hide()
        } else {
            cheatGui.Show("AutoSize Center")
            WinActivate("ahk_id " cheatGui.Hwnd)
        }
        return 
    }
    
    ; ==============================================================================
    ; 1. DATA EXTRACTION
    ; ==============================================================================
    cheatText := ""
    currentCategory := ""
    currentSubCategory := ""
    hasSub := false
    inLeaderBlock := false
    isLeaderCategory := false
    
    ; Array of files to parse
    filesToParse := [A_ScriptDir "\Modules\Hotstrings.ahk", A_ScriptDir "\Modules\Keybindings.ahk"]
    
    for _, currentFile in filesToParse 
    {
        if !FileExist(currentFile)
            continue
            
        fileData := FileRead(currentFile)
        
        ; Modern parsing loop bypasses the VS Code linter bug
        Loop Parse, fileData, "`n", "`r"
        {
            rawLine := A_LoopField
            line := Trim(rawLine)
            
            if (InStr(line, "[ FUNCTION LIBRARY ]")) {
                break
            }
            
            if (RegExMatch(line, '^\s*;\s*\[(.*?)\]', &match)) {
                currentCategory := Trim(match[1])
                currentSubCategory := "" 
                inLeaderBlock := false   
                isLeaderCategory := InStr(StrUpper(currentCategory), "LEADER KEY") > 0
            }
            else if (RegExMatch(line, '^\s*;\s*---\s*([a-zA-Z0-9].*?)\s*---', &match)) {
                currentSubCategory := Trim(match[1])
            }
            else if (RegExMatch(line, '^\s*([$#\^!+<>\w]+)::\s*\{', &match)) {
                inLeaderBlock := true
            }
            else if (inLeaderBlock && RegExMatch(rawLine, '^}')) {
                inLeaderBlock := false
            }
            
            hotkeyText := ""
            
            if (inLeaderBlock && RegExMatch(line, '^\s*case\s+"([^"]+)":', &matchCase)) {
                if RegExMatch(line, ';\s*(.*)$', &matchComment) {
                    desc := Trim(matchComment[1])
                    colonPos := InStr(desc, ":")
                    if (colonPos > 0 && colonPos <= 20) {
                        desc := Trim(SubStr(desc, colonPos + 1))
                    }
                    char := StrUpper(matchCase[1])
                    hotkeyText := "Press " char " -> " desc
                }
            }
            else if (!inLeaderBlock && RegExMatch(line, '^\s*([^;]+?)::.*?;(.*)', &match)) {
                hotkeyText := Trim(match[2])
            }
            
            if (hotkeyText != "") {
                if (currentCategory != "") {
                    cheatText .= "►CAT_TOP`n►CAT_TXT:" StrUpper(currentCategory) "`n►CAT_BOT`n"
                    currentCategory := "" 
                    hasSub := false
                }
                if (currentSubCategory != "") {
                    if (!isLeaderCategory) {
                        cheatText .= "►SUB_TXT:  ■ " currentSubCategory "`n"
                        hasSub := true
                    } else {
                        hasSub := false 
                    }
                    currentSubCategory := ""
                }
                
                prefix := hasSub ? "    ├─ " : "  ├─ "
                cheatText .= prefix . hotkeyText "`n"
            }
        }
    }
    
    ; ==============================================================================
    ; 2. UNBREAKABLE COLUMN SPLITTING
    ; ==============================================================================
    cheatText := Trim(cheatText, "`n`r")
    lines := StrSplit(cheatText, "`n")
    
    totalLines := lines.Length
    thirdMark := totalLines // 3
    twoThirdMark := thirdMark * 2
    
    col1 := [], col2 := [], col3 := []
    currentCol := 1
    maxCol1Len := 0, maxCol2Len := 0, maxCol3Len := 0
    
    For index, line in lines {
        isBreakPoint := (SubStr(line, 1, 8) == "►CAT_TOP" || SubStr(line, 1, 9) == "►SUB_TXT:")
        
        if (currentCol == 1 && index >= thirdMark && isBreakPoint)
            currentCol := 2
        else if (currentCol == 2 && index >= twoThirdMark && isBreakPoint)
            currentCol := 3
            
        actualLen := StrLen(line)
        if (SubStr(line, 1, 8) == "►CAT_TOP" || SubStr(line, 1, 8) == "►CAT_BOT")
            actualLen := 0 
        else if (SubStr(line, 1, 9) == "►CAT_TXT:")
            actualLen := StrLen(SubStr(line, 10)) + 4 
        else if (SubStr(line, 1, 9) == "►SUB_TXT:")
            actualLen := StrLen(SubStr(line, 10))
            
        if (currentCol == 1) {
            col1.Push(line)
            if (actualLen > maxCol1Len)
                maxCol1Len := actualLen
        } else if (currentCol == 2) {
            col2.Push(line)
            if (actualLen > maxCol2Len)
                maxCol2Len := actualLen
        } else {
            col3.Push(line)
            if (actualLen > maxCol3Len)
                maxCol3Len := actualLen
        }
    }
    
    maxRows := Max(col1.Length, col2.Length, col3.Length)
    if (maxRows == 0)
        maxRows := 1
        
    ; ==============================================================================
    ; 3. THE PERFECT GRID BUILDER
    ; ==============================================================================
    gapSize := 5 
    gapStr := ""
    Loop gapSize
        gapStr .= " "
        
    PadRight(str, len) {
        padLen := len - StrLen(str)
        if (padLen > 0) {
            Loop padLen
                str .= " "
        }
        return str
    }
    
    ProcessCell(cellValue, colMax) {
        if (SubStr(cellValue, 1, 8) == "►CAT_TOP" || SubStr(cellValue, 1, 8) == "►CAT_BOT") {
            lineStr := ""
            Loop colMax
                lineStr .= "="
            return lineStr
        }
        if (SubStr(cellValue, 1, 9) == "►CAT_TXT:") {
            txt := SubStr(cellValue, 10)
            spaces := (colMax - StrLen(txt)) // 2 
            padLeft := ""
            Loop Max(0, spaces)
                padLeft .= " "
            return PadRight(padLeft . txt, colMax)
        }
        if (SubStr(cellValue, 1, 9) == "►SUB_TXT:") {
            return PadRight(SubStr(cellValue, 10), colMax)
        }
        return PadRight(cellValue, colMax)
    }
    
    combinedText := "" 
    
    Loop maxRows {
        left  := (A_Index <= col1.Length) ? col1[A_Index] : ""
        mid   := (A_Index <= col2.Length) ? col2[A_Index] : ""
        right := (A_Index <= col3.Length) ? col3[A_Index] : ""
        
        l_fmt := ProcessCell(left, maxCol1Len)
        m_fmt := ProcessCell(mid, maxCol2Len)
        r_fmt := ProcessCell(right, maxCol3Len)
        
        combinedText .= l_fmt . gapStr . m_fmt . gapStr . r_fmt . "`n"
    }
    
    combinedText := Trim(combinedText, " `n`r")
    
    ; Prevent Windows from rendering "&" as an invisible accelerator line
    combinedText := StrReplace(combinedText, "&", "&&")
    
    ; ==============================================================================
    ; 4. NATIVE OS TEXT MEASUREMENT & SMART MULTI-MONITOR DETECTION
    ; ==============================================================================
    
    ; Detect which monitor the mouse is currently on
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    activeMonitor := 1
    
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        if (mX >= mLeft && mX <= mRight && mY >= mTop && mY <= mBottom) {
            activeMonitor := A_Index
            break
        }
    }
    
    ; Get the exact work area of the active monitor
    MonitorGetWorkArea(activeMonitor, &waLeft, &waTop, &waRight, &waBottom)
    monWidth := waRight - waLeft
    monHeight := waBottom - waTop
    
    maxGuiW := Floor(monWidth * 1)
    maxGuiH := Floor(monHeight * 1) 
    
    ; Start massive, and let it shrink
    fontSize := 36 
    textW := 0, textH := 0
    
    Loop {
        ; Force AHK to ignore Windows Zoom
        tempGui := Gui("-DPIScale") 
        tempGui.SetFont("s" fontSize " w700", "Consolas")
        
        tempText := tempGui.Add("Text", "", combinedText)
        tempText.GetPos(,, &textW, &textH)
        tempGui.Destroy()
        
        reqGuiW := textW + 80
        reqGuiH := textH + 80
        
        if ((reqGuiW <= maxGuiW) && (reqGuiH <= maxGuiH)) || (fontSize <= 8)
            break
            
        fontSize-- 
    }
    
    ; ==============================================================================
    ; 5. UI RENDERING & PERFECT CENTERING
    ; ==============================================================================
    
    ; Block Windows Zoom on the final render as well
    cheatGui := Gui("+AlwaysOnTop -Caption -Border -DPIScale", "AHK Master Cheatsheet")
    cheatGui.BackColor := "1E1E1E" 
    cheatGui.SetFont("s" fontSize " w700", "Consolas")  
    
    cheatGui.MarginX := 30
    cheatGui.MarginY := 20
    
    cheatGui.Add("Text", "w" textW " h" textH " Background1E1E1E cD4D4D4", combinedText)
    
    focusTrap := cheatGui.Add("Edit", "xp yp w0 h0 Background1E1E1E -Border")
    
    cheatGui.OnEvent("Escape", (*) => cheatGui.Hide())
    cheatGui.OnEvent("Close", (*) => cheatGui.Hide())
    
    ; Render invisibly on the CURRENT monitor to avoid the "DPI Void" corruption
    cheatGui.Show("Hide AutoSize x" waLeft " y" waTop)
    
    ; Measure the exact inflated hardware pixels
    cheatGui.GetPos(,, &realW, &realH)
    
    ; Calculate perfect center
    guiX := waLeft + (monWidth - realW) // 2
    guiY := waTop + (monHeight - realH) // 2
    
    ; Show it at the perfect coordinates
    cheatGui.Show("x" guiX " y" guiY)
    
    WinActivate("ahk_id " cheatGui.Hwnd)
    focusTrap.Focus()
}

; ==============================================================================
; 6. THE FOCUS FIX (Global Escape Override)
; ==============================================================================
#HotIf WinExist("AHK Master Cheatsheet")
~Escape:: {
    global cheatGui
    if (cheatGui) {
        cheatGui.Hide()
    }
}
#HotIf