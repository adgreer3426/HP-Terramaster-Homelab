SOURCE  := HomeNAS_Setup_Guide.md
META    := metadata.yaml
OUTPUT  := HomeNAS_Setup_Guide.pdf
ZIP     := HomeNAS_Setup_Guide.zip
ENGINE  := tectonic

PANDOC_FLAGS := \
	--from markdown \
	--template ./eisvogel.latex \
	--pdf-engine=$(ENGINE) \
	--highlight-style=tango \
	--top-level-division=chapter \
	--metadata-file=$(META)

.PHONY: pdf zip clean open

pdf: $(OUTPUT)

$(OUTPUT): $(SOURCE) $(META)
	pandoc $(SOURCE) -o $(OUTPUT) $(PANDOC_FLAGS)

zip: $(ZIP)

$(ZIP): $(OUTPUT) bonus/README.md
	rm -f $(ZIP)
	zip -r $(ZIP) $(OUTPUT) bonus/ -x "*.DS_Store" "*/._*" "bonus/.DS_Store"
	@echo "Built $(ZIP) — ready to upload to Gumroad."

open: pdf
	open $(OUTPUT)

clean:
	rm -f $(OUTPUT) $(ZIP)
