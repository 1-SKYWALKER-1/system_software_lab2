CC = gcc
CFLAGS = -Wall -Wextra -std=c99
CFLAGS_USER ?=

ifeq ($(BUILD_TYPE),shared)
CFLAGS_FINAL = $(CFLAGS) -fPIC $(CFLAGS_USER)
else
CFLAGS_FINAL = $(CFLAGS) $(CFLAGS_USER)
endif

LDFLAGS =
LDFLAGS_USER ?=
LDFLAGS_FINAL = $(LDFLAGS) $(LDFLAGS_USER)

CHECKER =
BUILD_DIR = build
DEFAULT_LIBRARY_TYPE = object
TARGET = $(BUILD_DIR)/program
STATIC_TARGET = $(BUILD_DIR)/libmylib.a
SHARED_TARGET = $(BUILD_DIR)/libmylib.so
OBJS = $(patsubst src/%.c, $(BUILD_DIR)/%.o, $(wildcard src/*.c))

$(shell mkdir -p $(BUILD_DIR))

ifeq ($(BUILD_TYPE),shared)
$(TARGET): src/main.o $(SHARED_TARGET)
	$(CC) $(CFLAGS_FINAL) -o $@ $^ -L$(BUILD_DIR) -lmylib $(LDFLAGS_FINAL)
else
$(TARGET): src/main.o $(STATIC_TARGET)
	$(CC) $(CFLAGS_FINAL) -static -o $@ $^ -L$(BUILD_DIR) -lmylib $(LDFLAGS_FINAL)
endif

$(SHARED_TARGET): $(filter-out src/main.o, $(OBJS))
	$(CC) -shared -o $@ $^

$(STATIC_TARGET): $(filter-out src/main.o, $(OBJS))
	ar rcs $@ $^

$(BUILD_DIR)/%.o: src/%.c
	$(CC) $(CFLAGS_FINAL) -c -o $@ $<

check:
	@if [ "$(CHECKER)" = "checkpatch.pl" ]; then \
		./checkpatch.pl --no-tree -f --showfile --fix src/*.c; \
	elif [ "$(CHECKER)" = "cppcheck" ]; then \
		cppcheck --enable=all --suppress=missingIncludeSystem src/*.c; \
	else \
		echo "Invalid checker specified. Please choose either  'CHECKER=checkpatch.pl' or 'CHECKER=cppcheck'."; \
	fi
 
clean:
ifeq ($(KEEP_LIBS), 1)
	rm -rf $(BUILD_DIR)/*.o
	rm -rf $(TARGET)
else
	rm -rf $(BUILD_DIR)
endif

install: $(TARGET)
ifndef DESTDIR
	@echo "Error: Destination directory is not specified. Usage: make install DESTDIR=<directory>"
else
	mkdir -p $(DESTDIR)
	cp $(TARGET) $(DESTDIR)/program
endif

.PHONY: check clean install

















