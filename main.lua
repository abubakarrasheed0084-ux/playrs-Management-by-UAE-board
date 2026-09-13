require "import" 
import "android.widget.*" 
import "com.androlua.*" 
import "android.content.Intent"
import "android.net.Uri"
import "android.content.DialogInterface"
import "android.content.Context"
import "android.view.KeyEvent"
import "android.media.MediaPlayer"
import "org.json.JSONObject"
import "org.json.JSONArray"
import "java.io.File"
import "java.io.FileInputStream"
import "java.io.InputStreamReader"
import "java.io.BufferedReader"
import "android.os.Build"
import "android.os.Environment"
import "android.provider.Settings"

-- Helper function to safely extract text from items
local function getItemText(parent, view, position)
  pcall(function()
    local adapter = parent.getAdapter()
    if adapter then
      local item = adapter.getItem(position)
      if item then return tostring(item) end
    end
  end)
  if view and view.Text then return tostring(view.Text) end
  return ""
end

-- Helper Adapter creator for GridViews/ListViews
local function setSimpleAdapter(view, itemsArray)
  local adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(itemsArray))
  if view then view.Adapter = adapter end
  return adapter
end

-- SharedPreferences کا استعمال
local sp = this.getSharedPreferences("CricketAppData", Context.MODE_PRIVATE)
local editor = sp.edit()

-- Sound Enabled Setting (ڈیفالٹ: true)
local isSoundEnabled = sp.getBoolean("sound_enabled", true)

-- Click sound play karne ke liye function
function playClickSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/Playrs Data Menij By UAE Hand Cricket Board/sound.mp3/click.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer)
        mediaPlayer.release()
      end
    })
  end)
end

-- Unsold sound play karne ke liye function
function playUnsoldSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/Playrs Data Menij By UAE Hand Cricket Board/sound.mp3/Unsold player.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer)
        mediaPlayer.release()
      end
    })
  end)
end

-- Sold sound play karne ke liye function
function playSoldSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/Playrs Data Menij By UAE Hand Cricket Board/sound.mp3/Player sold.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer)
        mediaPlayer.release()
      end
    })
  end)
end

-- اسٹور سے پرانا ڈیٹا لوڈ کرنے کے لیے فنکشن
function loadData()
  tournaments = {}
  registeredPlayers = {} -- ٹورنامنٹ وائز ڈرافٹ/رجسٹرڈ پلیئرز
  unsoldPlayersData = {} -- ٹورنامنٹ وائز انسولڈ پلیئرز
  teamsData = {}         -- ٹورنامنٹ وائز ٹیمز لسٹ
  soldPlayersData = {}   -- ٹیم وائز سولڈ پلیئرز (Structured Table)
  teamBudgetsData = {}   -- ٹیم وائز بجٹ ڈیٹا

  local tourJsonStr = sp.getString("tournaments_list", nil)
  local regJsonStr = sp.getString("registered_players", nil)
  local unsoldJsonStr = sp.getString("unsold_players", nil)
  local teamsJsonStr = sp.getString("teams_data", nil)
  local soldJsonStr = sp.getString("sold_players_v2", nil)
  local budgetJsonStr = sp.getString("team_budgets", nil)
  
  if tourJsonStr ~= nil then
    local tourObj = JSONObject(tourJsonStr)
    local keys = tourObj.keys()
    while keys.hasNext() do
      local key = tostring(keys.next())
      table.insert(tournaments, tourObj.getString(key))
    end
  end

  if regJsonStr ~= nil then
    local obj = JSONObject(regJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      registeredPlayers[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(registeredPlayers[k], arr.getString(i))
      end
    end
  end

  if unsoldJsonStr ~= nil then
    local obj = JSONObject(unsoldJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      unsoldPlayersData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(unsoldPlayersData[k], arr.getString(i))
      end
    end
  end

  if teamsJsonStr ~= nil then
    local obj = JSONObject(teamsJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      teamsData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(teamsData[k], arr.getString(i))
      end
    end
  end

  if soldJsonStr ~= nil then
    local obj = JSONObject(soldJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      soldPlayersData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        local pObj = arr.getJSONObject(i)
        table.insert(soldPlayersData[k], {
          name = pObj.getString("name"),
          price = pObj.optString("price", "0")
        })
      end
    end
  end

  if budgetJsonStr ~= nil then
    local obj = JSONObject(budgetJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      local bObj = obj.getJSONObject(k)
      teamBudgetsData[k] = {
        budget = bObj.optString("budget", "0"),
        basePrice = bObj.optString("basePrice", "0"),
        minPlayers = bObj.optString("minPlayers", "0"),
        maxPlayers = bObj.optString("maxPlayers", "0")
      }
    end
  end
end

-- ڈیٹا کو SharedPreferences میں محفوظ کرنے کا فنکشن
function saveData()
  local tourObj = JSONObject()
  for i, val in ipairs(tournaments) do
    tourObj.put(tostring(i), val)
  end
  
  local regObj = JSONObject()
  for k, v in pairs(registeredPlayers) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, name in ipairs(v) do arr.put(name) end
      regObj.put(k, arr)
    end
  end

  local unsoldObj = JSONObject()
  for k, v in pairs(unsoldPlayersData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, name in ipairs(v) do arr.put(name) end
      unsoldObj.put(k, arr)
    end
  end

  local teamsObj = JSONObject()
  for k, v in pairs(teamsData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, tname in ipairs(v) do arr.put(tname) end
      teamsObj.put(k, arr)
    end
  end

  local soldObj = JSONObject()
  for k, v in pairs(soldPlayersData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, pData in ipairs(v) do
        local pObj = JSONObject()
        pObj.put("name", pData.name)
        pObj.put("price", pData.price)
        arr.put(pObj)
      end
      soldObj.put(k, arr)
    end
  end

  local budgetObj = JSONObject()
  for k, v in pairs(teamBudgetsData) do
    local bObj = JSONObject()
    bObj.put("budget", v.budget or "0")
    bObj.put("basePrice", v.basePrice or "0")
    bObj.put("minPlayers", v.minPlayers or "0")
    bObj.put("maxPlayers", v.maxPlayers or "0")
    budgetObj.put(k, bObj)
  end

  editor.putString("tournaments_list", tourObj.toString())
  editor.putString("registered_players", regObj.toString())
  editor.putString("unsold_players", unsoldObj.toString())
  editor.putString("teams_data", teamsObj.toString())
  editor.putString("sold_players_v2", soldObj.toString())
  editor.putString("team_budgets", budgetObj.toString())
  editor.apply()
end

loadData()

-- صرف ایکسٹینشن کو بند کرنے کے لیے محفوظ طریقہ
function safeExitApp()
  pcall(function()
    if dlg then dlg.dismiss() end
  end)
end

-- ایگزٹ کنفرمیشن ڈائیلاگ
function showExitConfirmationDialog(parentDlg)
  local exitDlg = LuaDialog(this)
  exitDlg.setTitle("Exit Confirmation")
  exitDlg.setMessage("Do you want to exit this extension?")
  
  exitDlg.setButton("Yes", function(dialog, which)
    playClickSound()
    dialog.dismiss()
    if parentDlg then
      pcall(function() parentDlg.dismiss() end)
    end
    safeExitApp()
  end)
  
  exitDlg.setButton2("No", function(dialog, which)
    playClickSound()
    dialog.dismiss()
    pcall(function()
      if dlg then dlg.show() end
    end)
  end)
  
  exitDlg.show()
end

------------------------------------------------------------------
-- ** ری ڈیزائن شدہ خودمختار ڈیٹا امپورٹ کا نظام (FIXED FOLDER PICKER)**
------------------------------------------------------------------

-- پرمیشن چیک فنکشن
function checkStoragePermission()
  if Build.VERSION.SDK_INT >= 30 then
    if not Environment.isExternalStorageManager() then
      local intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
      intent.setData(Uri.parse("package:" .. this.getPackageName()))
      this.startActivity(intent)
      Toast.makeText(this, "Please allow storage access to browse folders!", Toast.LENGTH_LONG).show()
      return false
    end
  end
  return true
end

-- ٹیکسٹ اور CSV کا ڈیٹا پروسیس کرکے گلوبل لسٹ میں امپورٹ کرنے کا فنکشن
function processImportedText(content)
  if not content or content == "" then
    Toast.makeText(this, "File is empty or could not be read!", Toast.LENGTH_SHORT).show()
    return
  end

  local categoryKey = "Global_Imported_Players"
  if not registeredPlayers[categoryKey] then 
    registeredPlayers[categoryKey] = {} 
  end

  local count = 0
  for line in string.gmatch(content, "[^\r\n]+") do
    for name in string.gmatch(line, "[^,]+") do
      local trimmed = string.gsub(name, "^%s*(.-)%s*$", "%1")
      if trimmed ~= "" then
        table.insert(registeredPlayers[categoryKey], trimmed)
        count = count + 1
      end
    end
  end

  saveData()
  Toast.makeText(this, count .. " players imported successfully!", Toast.LENGTH_LONG).show()
end

-- لوکل فائل سے ٹیکسٹ ریڈ کرنے کا ہیلپر
local function readFileFromPath(filePath)
  local f = io.open(filePath, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

-- ڈیوائس کے مخصوص فولڈر سے امپورٹ (Fixed Folder Navigation)
function importFromFolderPicker(initialFolder)
  if not checkStoragePermission() then return end

  local dirPath = initialFolder or "/storage/emulated/0/"
  local folderFile = File(dirPath)
  
  if not folderFile.exists() or not folderFile.isDirectory() then
    Toast.makeText(this, "Directory does not exist!", Toast.LENGTH_SHORT).show()
    return
  end

  local fileList = folderFile.listFiles()
  local fileNames = {}
  local fileObjects = {}

  if dirPath ~= "/storage/emulated/0/" and dirPath ~= "/storage/emulated/0" then
    table.insert(fileNames, ".. (Go Back)")
    table.insert(fileObjects, "BACK")
  end

  if fileList then
    for i = 0, #fileList - 1 do
      local f = fileList[i]
      local name = f.getName()
      if f.isDirectory() then
        table.insert(fileNames, "📁 " .. name)
        table.insert(fileObjects, f)
      elseif name:lower():match("%.txt$") or name:lower():match("%.csv$") then
        table.insert(fileNames, "📄 " .. name)
        table.insert(fileObjects, f)
      end
    end
  end

  if #fileNames == 0 then
    Toast.makeText(this, "Folder is empty or contains no valid files!", Toast.LENGTH_SHORT).show()
    return
  end

  local fDlg = LuaDialog(this)
  fDlg.setTitle("Select File/Folder\n(" .. dirPath .. ")")
  local fLayout = { ListView, id="lstFiles", layout_width="fill", layout_height="300dp" }
  local views = {}
  fDlg.View = loadlayout(fLayout, views)
  
  views.lstFiles.Adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(fileNames))

  views.lstFiles.onItemClick = function(parent, view, position, id)
    playClickSound()
    local selectedObj = fileObjects[position + 1]

    if selectedObj == "BACK" then
      fDlg.dismiss()
      local parentDir = folderFile.getParent()
      importFromFolderPicker(parentDir)
    elseif selectedObj and selectedObj.isDirectory() then
      fDlg.dismiss()
      importFromFolderPicker(selectedObj.getAbsolutePath())
    elseif selectedObj and selectedObj.isFile() then
      fDlg.dismiss()
      local content = readFileFromPath(selectedObj.getAbsolutePath())
      processImportedText(content)
    end
  end

  fDlg.show()
end

-- سسٹم فائل چوزر (گوگل ڈرائیو، اے آئی، واٹس ایپ وغیرہ)
function openSystemFilePicker()
  pcall(function()
    local intent = Intent(Intent.ACTION_GET_CONTENT)
    intent.setType("*/*")
    local mimeTypes = {"text/plain", "text/csv", "text/comma-separated-values", "application/csv"}
    intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
    intent.addCategory(Intent.CATEGORY_OPENABLE)
    intent.putExtra("android.intent.extra.SHOW_ADVANCED", true)
    intent.putExtra(Intent.EXTRA_LOCAL_ONLY, false)

    local chooserIntent = Intent.createChooser(intent, "Import File Via")
    this.startActivityForResult(chooserIntent, 1001)
  end)
end

-- فائل کیچ (ActivityResult) ہینڈلر
function onActivityResult(requestCode, resultCode, data)
  if requestCode == 1001 and data ~= nil then
    pcall(function()
      local uri = data.getData()
      if uri ~= nil then
        local inputStream = this.getContentResolver().openInputStream(uri)
        local reader = BufferedReader(InputStreamReader(inputStream))
        local builder = StringBuilder()
        local line = reader.readLine()
        while line ~= nil do
          builder.append(line):append("\n")
          line = reader.readLine()
        end
        reader.close()
        inputStream.close()

        processImportedText(tostring(builder.toString()))
      end
    end)
  end
end

-- امپورٹ کے تمام اپشنز کا مینو
function showImportOptionsDialog()
  local options = {
    "Drive, AI & Cloud Storage",
    "Internal Storage Directory",
    "Downloads Folder",
    "Documents Folder"
  }

  local impDlg = LuaDialog(this)
  impDlg.setTitle("Import Options")

  local layout = { GridView, id="impGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  impDlg.View = loadlayout(layout, views)
  setSimpleAdapter(views.impGrid, options)

  views.impGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    impDlg.dismiss()
    local index = position + 1

    if index == 1 then
      openSystemFilePicker()
    elseif index == 2 then
      importFromFolderPicker("/storage/emulated/0/")
    elseif index == 3 then
      importFromFolderPicker("/storage/emulated/0/Download/")
    elseif index == 4 then
      importFromFolderPicker("/storage/emulated/0/Documents/")
    end
  end

  impDlg.setButton("Go Back", function(dialog)
    playClickSound()
    dialog.dismiss()
  end)
  impDlg.show()
end

------------------------------------------------------------------

-- نیا ٹورنامنٹ بنانے کا ڈائیلاگ
function showCreateTournamentDialog(onCreatedCallback)
  local tourneyDlg = LuaDialog(this)
  tourneyDlg.setTitle("Create New Tournament")
  
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Tournament Name:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtTournamentName", hint="Type Tournament Name", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" },
    { TextView, text="Teams (Comma or New Line Separated):", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtTeamsName", hint="Team A\nTeam B\nTeam C", layout_width="fill", layout_height="wrap", minLines=3 }
  }
  
  local views = {}
  tourneyDlg.View = loadlayout(layout, views)
  
  tourneyDlg.setButton("Save", function(dialog, which)
    playClickSound()
    local tName = views.edtTournamentName and tostring(views.edtTournamentName.Text) or ""
    local teamsStr = views.edtTeamsName and tostring(views.edtTeamsName.Text) or ""
    
    if tName == "" then
      Toast.makeText(this, "Please enter tournament name!", Toast.LENGTH_SHORT).show()
    else
      table.insert(tournaments, tName)
      teamsData[tName] = {}
      for team in string.gmatch(teamsStr, "[^,\r\n]+") do
        local trimmed = string.gsub(team, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(teamsData[tName], trimmed) end
      end
      saveData()
      Toast.makeText(this, "Tournament '" .. tName .. "' created successfully!", Toast.LENGTH_LONG).show()
      tourneyDlg.dismiss()
      if onCreatedCallback then onCreatedCallback() end
    end
  end)
  
  tourneyDlg.setButton2("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  tourneyDlg.show()
end

-- View Players کا ذیلی مینو
function showManageTournamentsMenu()
  local tItems = {
    "Import Data"
  }
  local tDlg = LuaDialog(this)
  tDlg.setTitle("View Players Options")
  local tLayout = { GridView, id="tGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  tDlg.View = loadlayout(tLayout, views)
  setSimpleAdapter(views.tGrid, tItems)
  
  views.tGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    tDlg.dismiss()
    local selectedText = getItemText(parent, view, position)
    if selectedText == "Import Data" then 
      showImportOptionsDialog()
    end
  end
  
  tDlg.setButton("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  tDlg.show()
end

-- Settings کا ڈائیلاگ
function showSettingsDialog()
  local setDlg = LuaDialog(this)
  setDlg.setTitle("Settings")
  
  local settingsLayout = {
    LinearLayout, orientation="horizontal", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Enable Sound:", textSize="16sp", textColor=0xFF000000, layout_weight=1 },
    { Switch, id="swSound", checked=isSoundEnabled }
  }
  
  local views = {}
  setDlg.View = loadlayout(settingsLayout, views)
  
  if views.swSound then
    views.swSound.setOnCheckedChangeListener({
      onCheckedChanged = function(buttonView, isChecked)
        isSoundEnabled = isChecked
        editor.putBoolean("sound_enabled", isChecked)
        editor.apply()
        if isChecked then
          playClickSound()
          Toast.makeText(this, "Sound Enabled", Toast.LENGTH_SHORT).show()
        else
          Toast.makeText(this, "Sound Disabled", Toast.LENGTH_SHORT).show()
        end
      end
    })
  end

  setDlg.setButton("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  setDlg.show()
end

-- ** Join Us Sub-Menu (FIXED) **
function showJoinUsMenu(parentDlg)
  local joinItems = {
    "WhatsApp Community",
    "Follow on WhatsApp Channel"
  }
  local jDlg = LuaDialog(this)
  jDlg.setTitle("Join Us")

  local jLayout = { GridView, id="jGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  jDlg.View = loadlayout(jLayout, views)
  setSimpleAdapter(views.jGrid, joinItems)

  views.jGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    jDlg.dismiss()
    if parentDlg then parentDlg.dismiss() end
    if dlg then dlg.dismiss() end

    local selectedText = getItemText(parent, view, position)
    if selectedText == "WhatsApp Community" then
      pcall(function()
        local intent = Intent(Intent.ACTION_VIEW)
        intent.setData(Uri.parse("https://chat.whatsapp.com/Jbrhiu4U49L3j4qCSsL6i1?s=cl&p=a&mlu=4&ilr=4"))
        this.startActivity(intent)
      end)
    elseif selectedText == "Follow on WhatsApp Channel" then
      pcall(function()
        local intent = Intent(Intent.ACTION_VIEW)
        intent.setData(Uri.parse("https://whatsapp.com/channel/0029VbDLCDtCnA7sQUFOle2u"))
        this.startActivity(intent)
      end)
    end
  end

  jDlg.setButton("Go back", function(dialog, which)
    playClickSound()
    dialog.dismiss()
  end)

  jDlg.show()
end

-- ** Contact Developer Sub-Menu (FIXED) **
function showContactDeveloperDialog(parentDlg)
  local cItems = {
    "Contact on Email",
    "Contact on WhatsApp"
  }
  local cDlg = LuaDialog(this)
  cDlg.setTitle("Contact Developer")

  local cLayout = { GridView, id="cGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  cDlg.View = loadlayout(cLayout, views)
  setSimpleAdapter(views.cGrid, cItems)

  views.cGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    cDlg.dismiss()
    if parentDlg then parentDlg.dismiss() end
    if dlg then dlg.dismiss() end

    local selectedText = getItemText(parent, view, position)
    if selectedText == "Contact on Email" then
      pcall(function()
        local intent = Intent(Intent.ACTION_SENDTO)
        intent.setData(Uri.parse("mailto:abubakarrasheed0084@gmail.com"))
        this.startActivity(intent)
      end)
    elseif selectedText == "Contact on WhatsApp" then
      pcall(function()
        local intent = Intent(Intent.ACTION_VIEW)
        intent.setData(Uri.parse("https://wa.me/923147798208"))
        this.startActivity(intent)
      end)
    end
  end

  cDlg.setButton("Go back", function(dialog, which)
    playClickSound()
    dialog.dismiss()
  end)

  cDlg.show()
end

-- ** About Dialog (FIXED) **
function showAboutMenu()
  local abItems = {
    "Join Us",
    "Contact Developer"
  }
  local abDlg = LuaDialog(this)
  abDlg.setTitle("About")
  
  local abLayout = { GridView, id="abGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  abDlg.View = loadlayout(abLayout, views)
  setSimpleAdapter(views.abGrid, abItems)

  views.abGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    local selectedText = getItemText(parent, view, position)
    if selectedText == "Join Us" then
      showJoinUsMenu(abDlg)
    elseif selectedText == "Contact Developer" then
      showContactDeveloperDialog(abDlg)
    end
  end

  abDlg.setButton("Go back", function(dialog, which)
    playClickSound()
    dialog.dismiss()
  end)
  
  abDlg.show()
end

-- پلیئر لسٹ ڈائیلاگ
function showCreateListDialog(targetTournament)
  local createDlg = LuaDialog(this)
  createDlg.setTitle("Create Player List (" .. targetTournament .. ")")
  
  local inputLayout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Player Names (Comma or New Line separated):", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtPlayerNames", hint="Player 1, Player 2...", layout_width="fill", layout_height="wrap", minLines=3 }
  }
  
  local views = {}
  createDlg.View = loadlayout(inputLayout, views)

  createDlg.setButton("Save", function(dialog, which)
    playClickSound()
    local enteredNames = views.edtPlayerNames and tostring(views.edtPlayerNames.Text) or ""
    
    if enteredNames == "" then
      Toast.makeText(this, "Please enter player names!", Toast.LENGTH_SHORT).show()
    else
      if not registeredPlayers[targetTournament] then registeredPlayers[targetTournament] = {} end
      for name in string.gmatch(enteredNames, "[^,\r\n]+") do
        local trimmed = string.gsub(name, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(registeredPlayers[targetTournament], trimmed) end
      end
      saveData()
      Toast.makeText(this, "Player list saved successfully!", Toast.LENGTH_LONG).show()
      createDlg.dismiss()
    end
  end)
  
  createDlg.setButton2("Go back", function(dialog, which) 
    playClickSound()
    createDlg.dismiss() 
  end)
  createDlg.show()
end

-- ٹیم بجٹ سیٹ کرنے کا ڈائیلاگ
function showSetTeamBudgetsDialog(targetTournament)
  local budgetDlg = LuaDialog(this)
  budgetDlg.setTitle("Set Team Budgets (" .. targetTournament .. ")")

  local currentBudget = teamBudgetsData[targetTournament] or {}

  local layout = {
    ScrollView, layout_width="fill", layout_height="wrap",
    {
      LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
      { TextView, text="Team Budget (Coins):", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtTeamBudget", text=currentBudget.budget or "", hint="Enter Budget Coins", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      
      { TextView, text="Base Price:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtBasePrice", text=currentBudget.basePrice or "", hint="Enter Base Price", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      
      { TextView, text="Minimum Players:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtMinPlayers", text=currentBudget.minPlayers or "", hint="Enter Min Players", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      
      { TextView, text="Maximum Players:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtMaxPlayers", text=currentBudget.maxPlayers or "", hint="Enter Max Players", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" }
    }
  }

  local views = {}
  budgetDlg.View = loadlayout(layout, views)

  budgetDlg.setButton("Confirm", function(dialog, which)
    playClickSound()
    teamBudgetsData[targetTournament] = {
      budget = views.edtTeamBudget and tostring(views.edtTeamBudget.Text) or "0",
      basePrice = views.edtBasePrice and tostring(views.edtBasePrice.Text) or "0",
      minPlayers = views.edtMinPlayers and tostring(views.edtMinPlayers.Text) or "0",
      maxPlayers = views.edtMaxPlayers and tostring(views.edtMaxPlayers.Text) or "0"
    }
    saveData()
    Toast.makeText(this, "Team Budgets Saved Successfully!", Toast.LENGTH_SHORT).show()
    budgetDlg.dismiss()
  end)

  budgetDlg.setButton2("Go back", function(dialog, which)
    playClickSound()
    budgetDlg.dismiss()
  end)

  budgetDlg.show()
end

-- پلیئر ڈرافٹنگ ڈائیلاگ
function showPlayerDraftingDialog(targetTournament)
  local draftDlg = LuaDialog(this)
  draftDlg.setTitle("Player Drafting (" .. targetTournament .. ")")

  local draftLayout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Select Player (Registered/Imported Players):", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnPlayer", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    
    { TextView, text="Sale Price:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtSalePrice", hint="Enter Amount", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    
    { TextView, text="Choose Team:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnTeam", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    
    { TextView, text="Status:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnStatus", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" }
  }

  local views = {}
  draftDlg.View = loadlayout(draftLayout, views)

  local statusList = {"Unsold", "Sold"}
  local statusAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(statusList))
  statusAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
  if views.spnStatus then views.spnStatus.Adapter = statusAdapter end

  local currentPlayers = {}
  local playerSources = {}

  local function buildCombinedPlayerList()
    currentPlayers = {}
    playerSources = {}

    local tourneyP = registeredPlayers[targetTournament] or {}
    for _, name in ipairs(tourneyP) do
      table.insert(currentPlayers, name)
      table.insert(playerSources, { key = targetTournament, name = name })
    end

    local globalP = registeredPlayers["Global_Imported_Players"] or {}
    for _, name in ipairs(globalP) do
      table.insert(currentPlayers, name)
      table.insert(playerSources, { key = "Global_Imported_Players", name = name })
    end
  end

  local currentTeams = teamsData[targetTournament] or {}

  local function refreshPlayerSpinner()
    buildCombinedPlayerList()
    local pList = {"No Players"}
    if #currentPlayers > 0 then pList = currentPlayers end
    local pAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(pList))
    pAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    if views.spnPlayer then views.spnPlayer.Adapter = pAdapter end
  end

  local function refreshTeamSpinner()
    currentTeams = teamsData[targetTournament] or {}
    local tmList = {"No Teams"}
    if #currentTeams > 0 then tmList = currentTeams end
    local tmAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(tmList))
    tmAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    if views.spnTeam then views.spnTeam.Adapter = tmAdapter end
  end

  refreshPlayerSpinner()
  refreshTeamSpinner()

  draftDlg.setButton("Confirm", function(dialog, which)
    if not views.spnStatus or not views.spnPlayer or not views.spnTeam then return end
    
    local statusPos = views.spnStatus.getSelectedItemPosition() + 1
    local status = statusList[statusPos] or "Unsold"
    local price = views.edtSalePrice and tostring(views.edtSalePrice.Text) or "0"

    if #currentPlayers == 0 then
      playClickSound()
      Toast.makeText(this, "No players available!", Toast.LENGTH_SHORT).show()
      return
    end

    local selectedPlayerIndex = views.spnPlayer.getSelectedItemPosition() + 1
    local pSourceInfo = playerSources[selectedPlayerIndex]
    local playerName = currentPlayers[selectedPlayerIndex]

    if status == "Sold" then
      playSoldSound()
      if #currentTeams == 0 or currentTeams[1] == "No Teams" then
        Toast.makeText(this, "No teams available to assign!", Toast.LENGTH_SHORT).show()
        return
      end
      
      local selectedTeam = currentTeams[views.spnTeam.getSelectedItemPosition() + 1]
      local recordKey = targetTournament .. "_" .. selectedTeam
      
      if not soldPlayersData[recordKey] then soldPlayersData[recordKey] = {} end
      table.insert(soldPlayersData[recordKey], {
        name = playerName,
        price = (price ~= "" and price or "0")
      })
      
      if pSourceInfo then
        local srcTable = registeredPlayers[pSourceInfo.key]
        if srcTable then
          for idx, n in ipairs(srcTable) do
            if n == playerName then
              table.remove(srcTable, idx)
              break
            end
          end
        end
      end

      saveData()
      
      Toast.makeText(this, playerName .. " SOLD to " .. selectedTeam, Toast.LENGTH_LONG).show()
      refreshPlayerSpinner()
      if views.edtSalePrice then views.edtSalePrice.Text = "" end
    else
      playUnsoldSound()
      if not unsoldPlayersData[targetTournament] then unsoldPlayersData[targetTournament] = {} end
      table.insert(unsoldPlayersData[targetTournament], playerName)
      
      if pSourceInfo then
        local srcTable = registeredPlayers[pSourceInfo.key]
        if srcTable then
          for idx, n in ipairs(srcTable) do
            if n == playerName then
              table.remove(srcTable, idx)
              break
            end
          end
        end
      end

      saveData()
      
      Toast.makeText(this, playerName .. " is marked as UNSOLD", Toast.LENGTH_SHORT).show()
      
      refreshPlayerSpinner()
      if views.edtSalePrice then views.edtSalePrice.Text = "" end
    end
  end)

  draftDlg.setButton2("Go back", function(dialog, which)
    playClickSound()
    draftDlg.dismiss()
  end)

  draftDlg.show()
end

-- انسولڈ پلیئر لسٹ کا ڈائیلاگ
function showUnsoldPlayerListDialog(targetTournament)
  local unsoldDlg = LuaDialog(this)
  unsoldDlg.setTitle("Unsold Player List (" .. targetTournament .. ")")

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Unsold Players:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnUnsoldPlayers", layout_width="fill", layout_height="wrap" }
  }

  local views = {}
  unsoldDlg.View = loadlayout(layout, views)

  local uList = unsoldPlayersData[targetTournament] or {}
  local showList = {}
  
  if #uList == 0 then
    showList = {"No Unsold Players"}
  else
    showList = uList
  end

  local pAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(showList))
  pAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
  if views.spnUnsoldPlayers then views.spnUnsoldPlayers.Adapter = pAdapter end

  unsoldDlg.setButton("Go back to Drafting", function(dialog, which)
    playClickSound()
    
    if #uList == 0 then
      Toast.makeText(this, "No unsold players to draft!", Toast.LENGTH_SHORT).show()
      return
    end

    local selIndex = (views.spnUnsoldPlayers and views.spnUnsoldPlayers.getSelectedItemPosition() or 0) + 1
    local selectedPlayer = uList[selIndex]

    if selectedPlayer then
      table.remove(unsoldPlayersData[targetTournament], selIndex)
      
      if not registeredPlayers[targetTournament] then registeredPlayers[targetTournament] = {} end
      table.insert(registeredPlayers[targetTournament], selectedPlayer)
      saveData()

      Toast.makeText(this, selectedPlayer .. " returned to Drafting!", Toast.LENGTH_SHORT).show()
      unsoldDlg.dismiss()
      showPlayerDraftingDialog(targetTournament)
    end
  end)

  unsoldDlg.setButton2("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  unsoldDlg.show()
end

-- پلیئر کو ایڈٹ کرنے کا ڈائیلاگ
function showEditPlayerDialog(targetTournament, teamName, playerIndex, refreshCallback)
  local recordKey = targetTournament .. "_" .. teamName
  local pList = soldPlayersData[recordKey] or {}
  local pData = pList[playerIndex]

  if not pData then return end

  local editPDlg = LuaDialog(this)
  editPDlg.setTitle("Edit Player (" .. pData.name .. ")")

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Player Name:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtPName", text=pData.name, layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    { TextView, text="Sale Price:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtPPrice", text=pData.price, inputType="number", layout_width="fill", layout_height="wrap" }
  }

  local views = {}
  editPDlg.View = loadlayout(layout, views)

  editPDlg.setButton("Save", function(d, w)
    playClickSound()
    local newName = views.edtPName and tostring(views.edtPName.Text) or ""
    local newPrice = views.edtPPrice and tostring(views.edtPPrice.Text) or "0"

    if newName == "" then
      Toast.makeText(this, "Player name cannot be empty!", Toast.LENGTH_SHORT).show()
      return
    end

    pData.name = newName
    pData.price = (newPrice ~= "" and newPrice or "0")
    saveData()
    Toast.makeText(this, "Player details updated!", Toast.LENGTH_SHORT).show()
    d.dismiss()
    if refreshCallback then refreshCallback() end
  end)

  editPDlg.setButton2("Mark Unsold", function(d, w)
    playUnsoldSound()
    local removedPlayer = table.remove(pList, playerIndex)
    
    if not unsoldPlayersData[targetTournament] then unsoldPlayersData[targetTournament] = {} end
    table.insert(unsoldPlayersData[targetTournament], removedPlayer.name)
    saveData()

    Toast.makeText(this, removedPlayer.name .. " moved to Unsold list!", Toast.LENGTH_SHORT).show()
    d.dismiss()
    if refreshCallback then refreshCallback() end
  end)

  editPDlg.show()
end

-- پلیئر آپشنز ڈائیلاگ
function showPlayerOptionsDialog(targetTournament, teamName, playerIndex, refreshCallback)
  local recordKey = targetTournament .. "_" .. teamName
  local pList = soldPlayersData[recordKey] or {}
  local pData = pList[playerIndex]

  if not pData then return end

  local optDlg = LuaDialog(this)
  optDlg.setTitle("Options for " .. pData.name)

  local items = {"Edit", "Rename", "Delete"}
  local layout = { GridView, id="optPGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  optDlg.View = loadlayout(layout, views)
  setSimpleAdapter(views.optPGrid, items)

  if views.optPGrid then
    views.optPGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local sel = getItemText(parent, view, position)
      if sel == "Edit" then
        optDlg.dismiss()
        showEditPlayerDialog(targetTournament, teamName, playerIndex, refreshCallback)
      elseif sel == "Rename" then
        optDlg.dismiss()
        local renDlg = LuaDialog(this)
        renDlg.setTitle("Rename Player")
        local renLayout = {
          LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
          { EditText, id="edtNewPName", text=pData.name, layout_width="fill", layout_height="wrap" }
        }
        local renViews = {}
        renDlg.View = loadlayout(renLayout, renViews)
        renDlg.setButton("OK", function(d, w)
          playClickSound()
          local nName = renViews.edtNewPName and tostring(renViews.edtNewPName.Text) or ""
          if nName ~= "" then
            pData.name = nName
            saveData()
            Toast.makeText(this, "Player Renamed!", Toast.LENGTH_SHORT).show()
            d.dismiss()
            if refreshCallback then refreshCallback() end
          end
        end)
        renDlg.setButton2("Cancel", function(d, w) d.dismiss() end)
        renDlg.show()
      elseif sel == "Delete" then
        optDlg.dismiss()
        local delDlg = LuaDialog(this)
        delDlg.setTitle("Delete Player")
        delDlg.setMessage("Are you sure you want to delete " .. pData.name .. " from " .. teamName .. "?")
        delDlg.setButton("Yes", function(d, w)
          playClickSound()
          table.remove(pList, playerIndex)
          saveData()
          Toast.makeText(this, "Player deleted!", Toast.LENGTH_SHORT).show()
          d.dismiss()
          if refreshCallback then refreshCallback() end
        end)
        delDlg.setButton2("No", function(d, w) d.dismiss() end)
        delDlg.show()
      end
    end
  end

  optDlg.setButton("Go back", function(d, w) d.dismiss() end)
  optDlg.show()
end

-- ٹیم تفاصیل کا ڈائیلاگ
function showTeamDetailDialog(targetTournament, selTeam)
  local detailDlg = LuaDialog(this)
  detailDlg.setTitle(selTeam .. " - Details")

  local recordKey = targetTournament .. "_" .. selTeam
  local pList = soldPlayersData[recordKey] or {}
  local bData = teamBudgetsData[targetTournament] or { budget="0", maxPlayers="0" }

  local function refreshTeamDetails()
    pList = soldPlayersData[recordKey] or {}
    local totalBudget = tonumber(bData.budget) or 0
    local maxPlayers = tonumber(bData.maxPlayers) or 0

    local pickedCount = #pList
    local remPlayers = (maxPlayers > pickedCount) and (maxPlayers - pickedCount) or 0

    local usedCoins = 0
    local playerNamesList = {}
    for _, p in ipairs(pList) do
      local pPrice = tonumber(p.price) or 0
      usedCoins = usedCoins + pPrice
      table.insert(playerNamesList, p.name .. " (Price: " .. p.price .. ")")
    end

    local remCoins = totalBudget - usedCoins

    local statsText = "Picked Players: " .. pickedCount .. "\n" ..
                      "Remaining Players: " .. remPlayers .. "\n" ..
                      "Total Coins: " .. totalBudget .. "\n" ..
                      "Used Coins: " .. usedCoins .. "\n" ..
                      "Remaining Coins: " .. remCoins

    return statsText, playerNamesList
  end

  local statsStr, pDisplayList = refreshTeamDetails()

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, id="txtStats", text=statsStr, textSize="14sp", textColor=0xFF000000, layout_marginBottom="12dp" },
    { TextView, text="Bought Players (Long Press for Options):", textSize="14sp", textColor=0xFF000000, layout_marginBottom="4dp" },
    { ListView, id="lstSoldP", layout_width="fill", layout_height="200dp" }
  }

  local views = {}
  detailDlg.View = loadlayout(layout, views)

  local function updateUI()
    local newStats, newPList = refreshTeamDetails()
    if views.txtStats then views.txtStats.Text = newStats end
    if #newPList == 0 then newPList = {"No Players Bought Yet"} end
    if views.lstSoldP then views.lstSoldP.Adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(newPList)) end
  end

  updateUI()

  if views.lstSoldP then
    views.lstSoldP.onItemLongClick = function(parent, view, position, id)
      playClickSound()
      if #pList > 0 then
        local pIndex = position + 1
        showPlayerOptionsDialog(targetTournament, selTeam, pIndex, function()
          updateUI()
        end)
        return true
      end
      return false
    end
  end

  detailDlg.setButton("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  detailDlg.show()
end

-- ٹیم ایڈٹ ڈائیلاگ
function showEditTeamDialog(targetTournament, teamIndex, oldTeamName, refreshCallback)
  local editTDlg = LuaDialog(this)
  editTDlg.setTitle("Edit Team Name")

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { EditText, id="edtEditTName", text=oldTeamName, layout_width="fill", layout_height="wrap" }
  }

  local views = {}
  editTDlg.View = loadlayout(layout, views)

  editTDlg.setButton("Save", function(d, w)
    playClickSound()
    local newName = views.edtEditTName and tostring(views.edtEditTName.Text) or ""
    newName = string.gsub(newName, "^%s*(.-)%s*$", "%1")

    if newName == "" then
      Toast.makeText(this, "Team name cannot be empty!", Toast.LENGTH_SHORT).show()
      return
    end

    if newName ~= oldTeamName then
      teamsData[targetTournament][teamIndex] = newName

      local oldKey = targetTournament .. "_" .. oldTeamName
      local newKey = targetTournament .. "_" .. newName
      soldPlayersData[newKey] = soldPlayersData[oldKey]
      soldPlayersData[oldKey] = nil

      saveData()
      Toast.makeText(this, "Team name updated!", Toast.LENGTH_SHORT).show()
      d.dismiss()
      if refreshCallback then refreshCallback() end
    else
      d.dismiss()
    end
  end)

  editTDlg.setButton2("Cancel", function(d, w) d.dismiss() end)
  editTDlg.show()
end

-- ٹیم آپشنز ڈائیلاگ
function showTeamOptionsDialog(targetTournament, teamIndex, teamName, refreshCallback)
  local optDlg = LuaDialog(this)
  optDlg.setTitle("Options for " .. teamName)

  local items = {"Edit", "Rename", "Delete"}
  local layout = { GridView, id="optTGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  optDlg.View = loadlayout(layout, views)
  setSimpleAdapter(views.optTGrid, items)

  if views.optTGrid then
    views.optTGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local sel = getItemText(parent, view, position)
      if sel == "Edit" or sel == "Rename" then
        optDlg.dismiss()
        showEditTeamDialog(targetTournament, teamIndex, teamName, refreshCallback)
      elseif sel == "Delete" then
        optDlg.dismiss()
        local delDlg = LuaDialog(this)
        delDlg.setTitle("Delete Team")
        delDlg.setMessage("Are you sure you want to delete '" .. teamName .. "'?")
        delDlg.setButton("Yes", function(d, w)
          playClickSound()
          table.remove(teamsData[targetTournament], teamIndex)
          local recordKey = targetTournament .. "_" .. teamName
          soldPlayersData[recordKey] = nil
          saveData()
          Toast.makeText(this, "Team deleted!", Toast.LENGTH_SHORT).show()
          d.dismiss()
          if refreshCallback then refreshCallback() end
        end)
        delDlg.setButton2("No", function(d, w) d.dismiss() end)
        delDlg.show()
      end
    end
  end

  optDlg.setButton("Go back", function(d, w) d.dismiss() end)
  optDlg.show()
end

-- ٹیمز دیکھنے کا ڈائیلاگ
function showViewTeamsDialog(targetTournament)
  local viewDlg = LuaDialog(this)
  viewDlg.setTitle("View Teams (" .. targetTournament .. ")")

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Participating Teams (Long press for options):", textSize="14sp", textColor=0xFF000000 },
    { ListView, id="lstTeams", layout_width="fill", layout_height="250dp" }
  }

  local views = {}
  viewDlg.View = loadlayout(layout, views)

  local currentTeamsList = teamsData[targetTournament] or {}

  local function refreshTeamsList()
    currentTeamsList = teamsData[targetTournament] or {}
    if views.lstTeams then
      views.lstTeams.Adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(currentTeamsList))
    end
  end

  refreshTeamsList()

  if views.lstTeams then
    views.lstTeams.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selTeam = currentTeamsList[position + 1]
      if selTeam then
        showTeamDetailDialog(targetTournament, selTeam)
      end
    end

    views.lstTeams.onItemLongClick = function(parent, view, position, id)
      playClickSound()
      local teamIndex = position + 1
      local selTeam = currentTeamsList[teamIndex]
      if selTeam then
        showTeamOptionsDialog(targetTournament, teamIndex, selTeam, function()
          refreshTeamsList()
        end)
        return true
      end
      return false
    end
  end

  viewDlg.setButton("Go back", function(dialog, functionWhich) 
    playClickSound()
    viewDlg.dismiss() 
  end)
  viewDlg.show()
end

-- سنگل ٹورنامنٹ مینو
function showSingleTournamentMenu(tName)
  local subItems = {
    "Create player list",
    "Set Team Budgets",
    "Player Drafting",
    "Unsold Player List",
    "View Teams"
  }
  
  local subDlg = LuaDialog(this)
  subDlg.setTitle(tName)
  local subLayout = { GridView, id="subGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  subDlg.View = loadlayout(subLayout, views)
  setSimpleAdapter(views.subGrid, subItems)

  if views.subGrid then
    views.subGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selectedText = getItemText(parent, view, position)
      if selectedText == "Create player list" then showCreateListDialog(tName)
      elseif selectedText == "Set Team Budgets" then showSetTeamBudgetsDialog(tName)
      elseif selectedText == "Player Drafting" then showPlayerDraftingDialog(tName)
      elseif selectedText == "Unsold Player List" then showUnsoldPlayerListDialog(tName)
      elseif selectedText == "View Teams" then showViewTeamsDialog(tName)
      end
    end
  end

  subDlg.setButton("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  subDlg.show()
end

-- Edit Tournament Dialog
function showEditTournamentDialog(tIndex, oldName, refreshCallback)
  local editDlg = LuaDialog(this)
  editDlg.setTitle("Edit Tournament Details")
  
  local currentTeams = teamsData[oldName] or {}
  local teamsStr = table.concat(currentTeams, "\n")

  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Tournament Name:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtEditName", text=oldName, layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" },
    { TextView, text="Teams (Comma or New Line Separated):", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtEditTeams", text=teamsStr, layout_width="fill", layout_height="wrap", minLines=3 }
  }
  
  local views = {}
  editDlg.View = loadlayout(layout, views)
  
  editDlg.setButton("Save", function(dialog, which)
    playClickSound()
    local newName = views.edtEditName and tostring(views.edtEditName.Text) or ""
    newName = string.gsub(newName, "^%s*(.-)%s*$", "%1")
    local newTeamsStr = views.edtEditTeams and tostring(views.edtEditTeams.Text) or ""

    if newName == "" then
      Toast.makeText(this, "Please enter tournament name!", Toast.LENGTH_SHORT).show()
      return
    end

    if newName ~= oldName then
      tournaments[tIndex] = newName
      registeredPlayers[newName] = registeredPlayers[oldName] or {}
      registeredPlayers[oldName] = nil

      unsoldPlayersData[newName] = unsoldPlayersData[oldName] or {}
      unsoldPlayersData[oldName] = nil
      
      teamBudgetsData[newName] = teamBudgetsData[oldName] or {}
      teamBudgetsData[oldName] = nil
      
      local keysToRename = {}
      for k, v in pairs(soldPlayersData) do
        if string.sub(k, 1, #oldName + 1) == oldName .. "_" then
          table.insert(keysToRename, k)
        end
      end
      
      for _, oldKey in ipairs(keysToRename) do
        local suffix = string.sub(oldKey, #oldName + 1)
        soldPlayersData[newName .. suffix] = soldPlayersData[oldKey]
        soldPlayersData[oldKey] = nil
      end
    end

    teamsData[newName] = {}
    if newName ~= oldName then
      teamsData[oldName] = nil
    end

    for team in string.gmatch(newTeamsStr, "[^,\r\n]+") do
      local trimmed = string.gsub(team, "^%s*(.-)%s*$", "%1")
      if trimmed ~= "" then 
        table.insert(teamsData[newName], trimmed) 
      end
    end

    saveData()
    Toast.makeText(this, "Tournament updated successfully!", Toast.LENGTH_SHORT).show()
    editDlg.dismiss()
    if refreshCallback then refreshCallback() end
  end)

  editDlg.setButton2("Cancel", function(dialog, which)
    playClickSound()
    editDlg.dismiss()
  end)

  editDlg.show()
end

-- Rename Tournament Dialog
function showRenameTournamentDialog(tIndex, oldName, refreshCallback)
  local renameDlg = LuaDialog(this)
  renameDlg.setTitle("Rename Tournament")
  
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Enter New Tournament Name:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtNewName", text=oldName, layout_width="fill", layout_height="wrap" }
  }
  
  local views = {}
  renameDlg.View = loadlayout(layout, views)
  
  renameDlg.setButton("OK", function(dialog, which)
    playClickSound()
    local newName = views.edtNewName and tostring(views.edtNewName.Text) or ""
    newName = string.gsub(newName, "^%s*(.-)%s*$", "%1")
    
    if newName == "" then
      Toast.makeText(this, "Please enter a valid name!", Toast.LENGTH_SHORT).show()
    elseif newName ~= oldName then
      tournaments[tIndex] = newName
      registeredPlayers[newName] = registeredPlayers[oldName] or {}
      registeredPlayers[oldName] = nil

      unsoldPlayersData[newName] = unsoldPlayersData[oldName] or {}
      unsoldPlayersData[oldName] = nil
      
      teamsData[newName] = teamsData[oldName] or {}
      teamsData[oldName] = nil
      
      teamBudgetsData[newName] = teamBudgetsData[oldName] or {}
      teamBudgetsData[oldName] = nil
      
      local keysToRename = {}
      for k, v in pairs(soldPlayersData) do
        if string.sub(k, 1, #oldName + 1) == oldName .. "_" then
          table.insert(keysToRename, k)
        end
      end
      
      for _, oldKey in ipairs(keysToRename) do
        local suffix = string.sub(oldKey, #oldName + 1)
        soldPlayersData[newName .. suffix] = soldPlayersData[oldKey]
        soldPlayersData[oldKey] = nil
      end
      
      saveData()
      Toast.makeText(this, "Tournament renamed successfully!", Toast.LENGTH_SHORT).show()
      renameDlg.dismiss()
      if refreshCallback then refreshCallback() end
    else
      renameDlg.dismiss()
    end
  end)
  
  renameDlg.setButton2("Cancel", function(dialog, which)
    playClickSound()
    renameDlg.dismiss()
  end)
  renameDlg.show()
end

-- Long Press Options Dialog
function showTournamentOptionsDialog(tIndex, tName, refreshCallback)
  local optDlg = LuaDialog(this)
  optDlg.setTitle("Options for " .. tName)
  
  local items = {"Edit", "Rename", "Delete"}
  local layout = { GridView, id="optGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  optDlg.View = loadlayout(layout, views)
  setSimpleAdapter(views.optGrid, items)
  
  if views.optGrid then
    views.optGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local sel = getItemText(parent, view, position)
      if sel == "Edit" then
        optDlg.dismiss()
        showEditTournamentDialog(tIndex, tName, refreshCallback)
      elseif sel == "Rename" then
        optDlg.dismiss()
        showRenameTournamentDialog(tIndex, tName, refreshCallback)
      elseif sel == "Delete" then
        optDlg.dismiss()
        local delDlg = LuaDialog(this)
        delDlg.setTitle("Confirm Delete")
        delDlg.setMessage("Are you sure you want to delete '" .. tName .. "'?")
        
        delDlg.setButton("OK", function(d, w)
          playClickSound()
          table.remove(tournaments, tIndex)
          registeredPlayers[tName] = nil
          unsoldPlayersData[tName] = nil
          teamsData[tName] = nil
          teamBudgetsData[tName] = nil
          saveData()
          Toast.makeText(this, "Tournament deleted!", Toast.LENGTH_SHORT).show()
          d.dismiss()
          if refreshCallback then refreshCallback() end
        end)
        
        delDlg.setButton2("Cancel", function(dialog, which)
          playClickSound()
          d.dismiss()
        end)
        
        delDlg.show()
      end
    end
  end

  optDlg.setButton("Go back", function(dialog, which)
    playClickSound()
    dialog.dismiss()
  end)
  optDlg.show()
end

-- Tournament Management Menu
function showTournamentManagementMenu()
  local pDlg = LuaDialog(this)
  pDlg.setTitle("Tournament Management")
  
  local function buildMenuList()
    local list = {"Create New Tournament"}
    for _, tName in ipairs(tournaments) do
      table.insert(list, tName)
    end
    return list
  end
  
  local currentList = buildMenuList()
  local pLayout = { GridView, id="pGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  pDlg.View = loadlayout(pLayout, views)
  setSimpleAdapter(views.pGrid, currentList)

  local function refreshMenu()
    currentList = buildMenuList()
    setSimpleAdapter(views.pGrid, currentList)
  end

  if views.pGrid then
    views.pGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selectedText = getItemText(parent, view, position)
      if selectedText == "Create New Tournament" then 
        showCreateTournamentDialog(function()
          refreshMenu()
        end)
      else
        showSingleTournamentMenu(selectedText)
      end
    end

    views.pGrid.onItemLongClick = function(parent, view, position, id)
      playClickSound()
      local selectedText = getItemText(parent, view, position)
      if selectedText ~= "Create New Tournament" then
        local tIndex = position 
        showTournamentOptionsDialog(tIndex, selectedText, function()
          refreshMenu()
        end)
        return true
      end
      return false
    end
  end

  pDlg.setButton("Go back", function(dialog, which) 
    playClickSound()
    dialog.dismiss() 
  end)
  pDlg.show()
end

-- بنیادی مینیو
items = {
  "Tournament Management",
  "View Players",
  "Settings",
  "About"
}

layout = { 
  GridView, id="grid", numColumns=1, layout_width="fill", layout_height="fill" 
}

local mainViews = {}
dlg = LuaDialog(this)
dlg.View = loadlayout(layout, mainViews)
setSimpleAdapter(mainViews.grid, items)
dlg.setTitle("Players Data Manage By UAE Hand Cricket Board")
dlg.setMessage("Welcome to Players Data Manage By UAE Hand Cricket Board")

dlg.setButton2("Exit", function(dialog, which)
  playClickSound()
  showExitConfirmationDialog(dlg)
end)

dlg.show()

if mainViews.grid then
  mainViews.grid.onItemClick = function(parent, view, position, id)
    playClickSound()
    local btnText = getItemText(parent, view, position)
    
    if btnText == "Tournament Management" then
      showTournamentManagementMenu()
    elseif btnText == "View Players" then
      showManageTournamentsMenu()
    elseif btnText == "Settings" then
      showSettingsDialog()
    elseif btnText == "About" then
      showAboutMenu()
    end
  end
end
