# MCP Servers

Model Context Protocol servers extend your AI coding tool's capabilities.
These servers work with any MCP-compatible client (opencode, Claude Code, etc.).

## Gemini Vision MCP

Adds image and document analysis capabilities using Google's Gemini model.

### Features

- **Image Analysis**: Describe, analyze, and extract text from images
- **Document Processing**: Analyze PDFs and documents
- **Multi-Image Comparison**: Compare multiple images at once
- **OCR**: Extract text from images
- **Smart Filename Suggestions**: Generate descriptive filenames for images
- **Video Analysis**: Analyze local video files and YouTube URLs

### Setup

1. **Get a Gemini API Key**
   - Visit: https://aistudio.google.com/apikey
   - Create a free API key (starts with `AIzaSy...`)

2. **Add to Environment**

   ```bash
   # Add to ~/.zshrc or ~/.bashrc
   export GEMINI_API_KEY='your-key-here'

   # Reload shell
   source ~/.zshrc
   ```

3. **Install Dependencies**

   ```bash
   pnpm install
   ```

4. **Configure the MCP server**

   Add to your `opencode.json` (or `opencode.jsonc`) at the vault root:

   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "mcp": {
       "gemini-vision": {
         "type": "local",
         "command": ["node", ".opencode/mcp-servers/gemini-vision.mjs"],
         "enabled": true,
         "environment": {
           "GEMINI_API_KEY": "{env:GEMINI_API_KEY}"
         }
       }
     }
   }
   ```

   You can verify the server is registered with:

   ```bash
   opencode mcp list
   ```

5. **Test Setup**

   ```bash
   pnpm test-gemini
   ```

### Available Tools

Once configured, these MCP tools become available:

- `analyze_image` - Analyze a single image
- `analyze_multiple` - Compare multiple images
- `extract_text` - OCR text extraction
- `compare_images` - Compare two images
- `suggest_image_filename` - Generate descriptive filename
- `analyze_document` - Analyze PDFs and documents

### Usage Examples

**Analyze Screenshot**

```
Analyze the image at 05_Attachments/screenshot.png
and tell me what it contains.
```

**Process Multiple Images**

```
Compare all images in 05_Attachments/Organized/
and identify common themes.
```

**Extract Text**

```
Extract all text from the PDF at
05_Attachments/document.pdf
```

**Rename Images**

```
Suggest better names for all images
in 05_Attachments/ based on their content.
```

**Video Analysis**

```
Analyze the video at 05_Attachments/video.mp4
```

### Supported Formats

- **Images:** JPG, JPEG, PNG, GIF, BMP, WebP
- **Videos:** MP4, AVI, MOV, WebM, MKV, WMV, FLV, 3GP, M4V
- **Documents:** PDF, TXT, DOC, DOCX, ODT, RTF
- **Special:** YouTube URLs (direct support without download)

### Troubleshooting

**"GEMINI_API_KEY not found"**

- Make sure you've added the key to your shell profile
- Restart your terminal and your AI tool

**"Cannot find module" errors**

```bash
# Reinstall dependencies
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

**Test API key directly**

```bash
curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"
```

Should return a list of models, not an error.

**Rate Limits**

- Free tier: 15 requests per minute
- Consider upgrading for heavy usage

## Adding More MCP Servers

1. Place MCP server file in `.opencode/mcp-servers/`
2. Add configuration to `opencode.json` under the `"mcp"` key
3. Document setup in this README
4. Add usage examples

For remote MCP servers, use `"type": "remote"` with a `"url"` instead of
`"command"`. opencode also supports OAuth authentication for remote servers —
see the [opencode MCP docs](https://opencode.ai/docs/mcp-servers) for details.

## Resources

- [opencode MCP Documentation](https://opencode.ai/docs/mcp-servers)
- [MCP Specification](https://modelcontextprotocol.io)
- [Gemini API Docs](https://ai.google.dev)
