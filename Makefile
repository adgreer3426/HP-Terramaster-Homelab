SOURCE  := HomeNAS_Setup_Guide.md
META    := metadata.yaml
OUTPUT  := HomeNAS_Setup_Guide.pdf
ENGINE  := tectonic

PANDOC_FLAGS := \
	--from markdown \
	--template ./eisvogel.latex \
	--pdf-engine=$(ENGINE) \
	--highlight-style=tango \
	--top-level-division=chapter \
	--metadata-file=$(META)

.PHONY: pdf clean open

pdf: $(OUTPUT)

$(OUTPUT): $(SOURCE) $(META)
	pandoc $(SOURCE) -o $(OUTPUT) $(PANDOC_FLAGS)

open: pdf
	open $(OUTPUT)

clean:
	rm -f $(OUTPUT)
