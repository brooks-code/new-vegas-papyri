# Fallout New Vegas dialogue (and more) dataset generator

**Salvaging scraps of conversation from the wasteland.**

![Banner Image](<img/Fallout_3_Van_Buren.jpg> "An image depicting two Fallout characters.")
<br>*Ever heard of Van Buren? That's the original (cancelled) first Fallout 3 game codename.*

## Genesis

> The motivation behind this script is to generate a dataset that I can use to experiment some computational linguistics and NLP methods on a corpus that captures the grit, slang, and broken etiquette of the Fallout speech. With that linguistic rubble in hand, you can play with topic models to unearth recurring rumors, build language models that mimic irradiated idioms or just train classifiers and measure how some patterns shape in-game dialects.

> [!INFO]
> The dataset is available on [Kaggle](https://www.kaggle.com/datasets/grimespoint/fallout-new-vegas-dataset) with an exploratory [notebook](https://www.kaggle.com/code/grimespoint/fallout-new-vegas-dataset-exploration) and in the Kaggle [archive repository](https://github.com/brooks-code/kaggle).

## Table of Contents

<details>
<summary>Contents - click to expand</summary>

- [Fallout New Vegas dialogue (and more) dataset generator](#fallout-new-vegas-dialogue-and-more-dataset-generator)
  - [Genesis](#genesis)
  - [Table of Contents](#table-of-contents)
  - [Overview and features](#overview-and-features)
  - [Requirements](#requirements)
  - [Usage](#usage)
  - [Output](#output)
  - [Configuration](#configuration)
  - [Procedures summary](#procedures-summary)
  - [Fallout New Vegas text records schema](#fallout-new-vegas-text-records-schema)
    - [Overview](#overview)
    - [At signature level](#at-signature-level)
      - [DIAL](#dial)
      - [INFO](#info)
      - [MESG](#mesg)
      - [NOTE](#note)
      - [LSCR](#lscr)
  - [Limitations](#limitations)
  - [Improvements](#improvements)
  - [Contributing](#contributing)
  - [Acknowledgments](#acknowledgments)
  - [License](#license)

</details>

## Overview and features

This Pascal/Delphi unit is a FNVEdit (xEdit FNV variant) script that scans loaded plugin files and exports select dialogue-related records and related metadata to a CSV file.

- Recursively scans GRUP containers to export `INFO, MESG, DIAL, NOTE, and LSCR` records to a CSV.
- Extracts text (`NAM1/DESC/FULL/TNAM`), menu button `ITXT`, content source, file name, FormID, EditorID, name, topic, quest, top-level path, and speaker.
- Multiple response lines or menu entries are joined with `|`.
- Encodes CR/LF as \n, quoting fields safely (doubling quotes and wrapping when needed).
- Reports progress every 500 records with a completion summary.

## Requirements

- Fallout New Vegas game (with or without extensions) installed on your computer.

- Properly configured [FNVEdit](https://www.nexusmods.com/newvegas/mods/34703) (or [there](https://github.com/TES5Edit/TES5Edit/releases/)). Tested with version 4.5.1

## Usage

1. Place the unit into your xEdit/script folder.
2. Load plugins in the appropriate xEdit build (FNVEdit, etc.) and select the appropriate `.esm` (or others) files.
3. Right click and select **apply script** on the left pane:
   - ![Example Image](</img/1SWYTIs-372733730.jpg> "Step 1: select apply script from the left pane. Source: NexusMods")
   - then choose and run `FNV_dialogue_export` from the list:
   - ![Example Image](</img/LnSbWQs-3417635174.jpg> "Step 2: run the script. Source: NexusMods")

## Output

- Output file: `<wbTempPath>Fallout_New_Vegas_dataset.csv`
  - Usuallly located within: `C:/Users/YourWindowsUserName/AppData/Local/Temp`, where `YourWindowsUserName` is your actual user name.

> [!WARNING]
> Output file is deleted from the `Temp` folder on application exit.

- CSV header:

```csv
signature;file_name;formID;editorID;text_content;content_source;name;topic;quest;topLevelPath;additional_content;speaker
```

| Field | Description | Note |
|---|---|---|
| **signature** | The signature of the record | MESG, NOTE, LSCR, DIAL, INFO |
| **file_name** | The name of the file that the record was found in | Plugin filename (.esm/.esp/.exe) |
| **formID** | The FormID of the record | 8-char hex values |
| **EditorID** | The EditorID of the record | |
| **text_content** | The text content of the record | Newlines encoded as `\n` |
| **content_source** | The source of the text content | Field name used (e.g., NAM1, DESC) |
| **name** | The name of the record | Typically extracted from FULL |
| **topic** | The topic of the record | Record type/category |
| **quest** | The quest associated with the record | May be empty |
| **topLevelPath** | The top-level path of the record | PathName output |
| **additional_content** | Additional content associated with the record | ITXT menu entries joined by `pipe symbol`|
| **speaker** | The speaker associated with the record | ANAM or similar field |

## Configuration

- **Output location:** the CSV is written to `wbTempPath` + `'Fallout_New_Vegas_dataset.csv'`. Modify the OutFile assignment in Initialize per your needs.
- **CSV delimiter:** to switch separators (for example to comma), replace each `';'` concatenation in `ScanContainer` and the header string in `Initialize` with the desired delimiter.
- **Recorded signatures:** to include additional record types, add their signature checks in `ScanContainer` (e.g., SigEquals(sig, 'SIGN')) and **implement an extraction logic** for their fields.
- **Progress interval:** change the frequency of progress messages by editing the condition `(RecordCounter mod 500 = 0)` to another modulus value.
- **Locale/encoding:** `TStringList.SaveToFile` uses system default encoding. For UTF-8 output, use `SaveToFile(OutFile, TEncoding.UTF8)` or an equivalent streaming write.

## Procedures summary

| Function | Purpose |
|---|---|
| **SigEquals(a, b)** | Case-insensitive signature compare. |
| **EncodeNewlines(s)** | Converts CR/LF (end of a line) to `\n`. |
| **QuoteCSV(s)** | Prepares a string for CSV (double quotes internal `"` as `""` and wraps field if needed). |
| **FileNameOf(e)** | Returns the plugin file name for a record. |
| **SafeEditValue(e, path)** | Returns element edit value or empty string on exception. |
| **CollectINFOResponses(info)** | Concatenates NAM1 responses from INFO records, separated by `pipe symbol`. |
| **CollectITXT(menuButtons)** | Concatenates ITXT button texts from MESG menu buttons, separated by `pipe symbol`. |
| **ScanContainer(container)** | Core recursive scanner that builds CSV lines and appends to OutLines. |
| **Initialize** | Entry point: prepares output, iterates files, saves CSV, prints summary. |

## Fallout New Vegas text records schema

### Overview

```markdown
Top-level file structure
PLUGIN (.EXE / .ESM / .ESP)
│
├── GRUP Top "DIAL"
│   └── DIAL (Dialogue Topic)
│       └── GRUP Topic Children
│           └── INFO (Dialogue Response)
│
├── GRUP Top "MESG"
│   └── MESG (Message)
│
├── GRUP Top "NOTE"
│   └── NOTE (Note / Terminal Entry)
│
├── GRUP Top "LSCR"
    └── LSCR (Loading Screen)
```

> [!WARNING]
> INFO records never exist at top level. They are always nested under DIAL → Topic Children.

### At signature level

<details>
<summary>DIAL - click to expand</summary>
#### DIAL

```markdown
DIAL — Dialogue Topic

DIAL
│
├── EDID                → EditorID
├── FULL - Name         → Topic text (player-visible)
│
├── DATA - DATA
│   └── Type            → Topic type
│
├── Record Header
│   └── FormID
│
└── GRUP Topic Children
    └── INFO [...]
```

Sources and imputations:

| CSV column | Source |
|---|---|
| signature | "DIAL" |
| file_name | owning plugin |
| formID | DIAL FormID |
| editorID | EDID |
| text_content | FULL - Name |
| content_source | "FULL - Name" |
| name | FormID (record header) |
| topic | DATA\Type |
| quest | (empty) |
| topLevelPath | (empty) |
| additional_content | (empty) |
| speaker | (empty) |

</details>

<details>
<summary>INFO - click to expand</summary>
#### INFO

```markdown
INFO — Dialogue Response (most complex)

INFO
│
├── EDID
├── ANAM - Speaker      → Speaker (NPC/reference)
│
├── Topic               → Parent topic reference
│
├── DATA - DATA
│   └── Type            → INFO subtype
│
├── QSTI - Quest        → Owning quest (if any)
│
├── Responses
│   ├── Response
│   │   └── NAM1 - Response Text
│   ├── Response
│   │   └── NAM1 - Response Text
│   └── ...
│
└── (implicit parent path via DIAL)
```

Sources and imputations:

| CSV column | Source |
|---|---|
| signature | "INFO" |
| file_name | owning plugin |
| formID | INFO FormID |
| EditorID | EDID |
| text_content | concatenated Responses\Response\NAM1 |
| content_source | "NAM1" |
| Name | Topic |
| Topic | DATA\Type |
| Quest | QSTI - Quest |
| topLevelPath | full xEdit path to INFO |
| additional_content | (empty) |
| speaker | ANAM - Speaker |

> [!NOTE]
> Responses are a repeating structure. Flattened using `|` as separator.

</details>

<details>
<summary>MESG - click to expand</summary>
#### MESG

```markdown
MESG — Message Box

MESG
│
├── EDID
├── FULL - Name         → Message title
├── DESC - Description  → Main message text
│
├── Menu Buttons
│   ├── Menu Button
│   │   └── ITXT - Button Text
│   ├── Menu Button
│   │   └── ITXT - Button Text
│   └── ...
```

Sources and imputations:

| CSV column | Source |
|---|---|
| signature | "MESG" |
| file_name | plugin |
| formID | MESG FormID |
| EditorID | EDID |
| text_content | DESC - Description |
| content_source | "DESC - Description" |
| Name | FULL - Name |
| Topic | (empty) |
| Quest | (empty) |
| topLevelPath | (empty) |
| additional_content | concatenated Menu Buttons\ITXT |
| speaker | (empty) |

</details>

<details>
<summary>NOTE - click to expand</summary>
#### NOTE

```markdown
NOTE — Notes / Terminal Notes

NOTE
│
├── EDID
├── FULL - Name
│
├── DATA - Type         → Note type
│
├── TNAM - Text / Topic
│   └── Text            → Note content
│
├── Quests
│   └── ONAM - Quest    → Linked quest
```

Sources and imputations:

| CSV column | Source |
|---|---|
| signature | "NOTE" |
| file_name | plugin |
| formID | NOTE FormID |
| EditorID | EDID |
| text_content | TNAM\Text |
| content_source | "TNAM - Text / Topic" |
| Name | FULL - Name |
| Topic | DATA - Type |
| Quest | Quests\ONAM |
| topLevelPath | (empty) |
| additional_content | (empty) |
| speaker | (empty) |

</details>

<details>
<summary>LSCR - click to expand</summary>
#### LSCR

```markdown
LSCR — Loading Screen

LSCR
│
├── EDID
├── DESC - Description → Loading screen text
```

Sources and imputations:

| CSV column | Source |
|---|---|
| signature | "LSCR" |
| file_name | plugin |
| formID | LSCR FormID |
| EditorID | EDID |
| text_content | DESC - Description |
| content_source | "DESC - Description" |
| Name | (empty) |
| Topic | (empty) |
| Quest | (empty) |
| topLevelPath | (empty) |
| additional_content | (empty) |
| speaker | (empty) |

</details>

## Limitations

- **Environment dependent:** does not run as a standalone Delphi program. Requires xEdit runtime functions (*ElementByName, GetEditValue, FileCount, wbTempPath, AddMessage, etc.*) that are accessible within FNVEdit.
- **Record coverage:** only scans `INFO, MESG, DIAL, NOTE, and LSCR` records (and `GRUP` containers). Other records are ignored unless implemented.
- **Performance** the `ScanContainer` procedure is recursive and will traverse GRUP/group hierarchies by calling itself for each nested group. This approach is slower in terms of performance.
- **CSV separator:** Uses `;` as the delimiter. If downstream tools expect `,`, import errors or incorrect parsing may occur.
- **Field assumptions:** Extracted fields are based on common paths used in Bethesda/FO editors; custom or unexpected record layouts may yield empty or incomplete values.
- **Memory usage:** Loads all output lines into memory via `TStringList` before saving; very large exports may consume significant RAM.
- **Progress granularity:** Progress messages are emitted every 500 records.
- **Error handling:** `SafeEditValue` suppresses exceptions and returns empty strings; this hides field-specific errors but may mask data issues.

## Improvements

- [ ] Needs further adaptation to extract contents from other Bethesda games (Skyrim, Fallout 4..).

- [ ] Improve performance (limit the recursion, stream output from `TStringList`).

## Contributing

Feel free to open issues or discuss any improvements. Contributions are welcome! Each contribution and feedback helps improve this project and my skills - it's always an honour :)

    Fork the repository.
    Create a branch for your feature or bug fix.
    Submit a pull request with your changes.

## Acknowledgments

The authors of the [xEdit](https://github.com/TES5Edit) library and especially the maintainers of the [FNVEdit](https://github.com/TES5Edit/TES5Edit) build.

## License

Provided under the [Unlicense](https://unlicense.org/) license.

🀅
