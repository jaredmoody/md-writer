EditLine = require "../../lib/commands/edit-line"

describe "EditLine", ->
  [editor, editLine] = []

  beforeEach ->
    waitsForPromise -> atom.workspace.open("empty.markdown")
    runs -> editor = atom.workspace.getActiveTextEditor()

  describe "insertNewLine", ->
    beforeEach -> editLine = new EditLine("insert-new-line")

    it "does not affect normal new line", ->
      editor.setText "this is normal line"
      editor.setCursorBufferPosition([0, 4])

      editLine.trigger()
      expect(editor.getText()).toBe """
      this
       is normal line
      """

    it "continue if config inlineNewLineContinuation enabled", ->
      atom.config.set("markdown-writer.inlineNewLineContinuation", true)

      editor.setText "- inline line"
      editor.setCursorBufferPosition([0, 8])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "- inline"
        "-  line"
      ].join("\n")

    it "continue after unordered list line", ->
      editor.setText "- line"
      editor.setCursorBufferPosition([0, 6])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "- line"
        "- " # trailing whitespace
      ].join("\n")

    it "continue after ordered task list line", ->
      editor.setText """
      1. [ ] Epic Tasks
        1. [X] Sub-task A
      """
      editor.setCursorBufferPosition([1, 19])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "1. [ ] Epic Tasks"
        "  1. [X] Sub-task A"
        "  2. [ ] " # trailing whitespace
      ].join("\n")

    it "continue after blockquote line", ->
      editor.setText """
      > Your time is limited, so don’t waste it living someone else’s life.
      """
      editor.setCursorBufferPosition([0, 69])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "> Your time is limited, so don’t waste it living someone else’s life."
        "> " # trailing whitespace
      ].join("\n")

    it "not continue after empty unordered task list line", ->
      editor.setText """
      - [ ]
      """
      editor.setCursorBufferPosition([0, 5])

      editLine.trigger()
      expect(editor.getText()).toBe ["", ""].join("\n")

    it "not continue after empty ordered list line", ->
      editor.setText """
      1. [ ] parent
        - child
        -
      """
      editor.setCursorBufferPosition([2, 4])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "1. [ ] parent"
        "  - child"
        "2. [ ] "
      ].join("\n")

    it "not continue after empty ordered paragraph", ->
      editor.setText """
      1. parent
        - child has a paragraph

          paragraph one

          paragraph two

        -
      """
      editor.setCursorBufferPosition([7, 3])

      editLine.trigger()
      expect(editor.getText()).toBe [
        "1. parent"
        "  - child has a paragraph"
        ""
        "    paragraph one"
        ""
        "    paragraph two"
        ""
        "2. "
      ].join("\n")

  describe "indentListLine", ->
    beforeEach -> editLine = new EditLine("indent-list-line")

    it "indent line if it is at head of line", ->
      editor.setText "  normal line"
      editor.setCursorBufferPosition([0, 1])

      editLine.trigger()
      expect(editor.getText()).toBe("    normal line")

    it "indent line if it is a list", ->
      editor.setText "- list"
      editor.setCursorBufferPosition([0, 5])

      editLine.trigger()
      expect(editor.getText()).toBe("  - list")

    it "insert space if it is text", ->
      editor.setText "texttext"
      editor.setCursorBufferPosition([0, 4])

      editLine.trigger()
      expect(editor.getText()).toBe("text text")
