local ogp = require("ogp-preview.ogp")

describe("ogp", function()
	describe("_extract_ogp_image_url", function()
		it("should extract og:image with property first", function()
			local html = [[
        <html>
          <head>
            <meta property="og:image" content="https://example.com/image.png">
          </head>
        </html>
      ]]
			local result = ogp._extract_ogp_image_url(html)
			assert.equals("https://example.com/image.png", result)
		end)

		it("should extract og:image with content first", function()
			local html = [[
        <html>
          <head>
            <meta content="https://example.com/image.png" property="og:image">
          </head>
        </html>
      ]]
			local result = ogp._extract_ogp_image_url(html)
			assert.equals("https://example.com/image.png", result)
		end)

		it("should extract og:image with single quotes", function()
			local html = [[
        <html>
          <head>
            <meta property='og:image' content='https://example.com/image.png'>
          </head>
        </html>
      ]]
			local result = ogp._extract_ogp_image_url(html)
			assert.equals("https://example.com/image.png", result)
		end)

		it("should return nil for missing og:image", function()
			local html = [[
        <html>
          <head>
            <meta property="og:title" content="Test">
          </head>
        </html>
      ]]
			local result = ogp._extract_ogp_image_url(html)
			assert.is_nil(result)
		end)

		it("should handle GitHub repository page HTML", function()
			local html = [[
        <meta property="og:image" content="https://opengraph.githubassets.com/abc123/neovim/neovim">
      ]]
			local result = ogp._extract_ogp_image_url(html)
			assert.equals("https://opengraph.githubassets.com/abc123/neovim/neovim", result)
		end)
	end)
end)
