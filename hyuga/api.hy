(require hyrule * :readers *)
(require hyrule.argmove [-> ->>])

(require hyuga.util [guard try-else])

(import hyrule.iterables [butlast drop-last])
(import hyrule.collections [assoc])
(import toolz.itertoolz *)
(import toolz.dicttoolz *)
(import functools [partial])

(import hyuga.log [logger])
(import hyuga.global [$GLOBAL])
(import hyuga.sym.loader *)
(import hyuga.sym.helper *)

(defn parse-src!
  [src root-uri doc-uri]
  "TODO: doc"
  (logger.debug f"parse-src!: start. $SYMS.count={(count ($GLOBAL.get-$SYMS))}, root-uri={root-uri}, doc-uri={doc-uri}")
  (when (= 0 (count ($GLOBAL.get-$SYMS)))
    (load-builtin!)
    (load-hy-special!)
    (load-sys!)
    (load-venv! root-uri doc-uri))
  (load-src! src root-uri doc-uri)
  (logger.debug f"parse-src!: finished. $SYMS.count={(count ($GLOBAL.get-$SYMS))}, root-uri={root-uri}, doc-uri={doc-uri}"))

(defn get-details
  [full-sym root-uri doc-uri]
  "TODO: doc"
  (logger.debug f"get-details: full-sym={full-sym} root-uri={root-uri} doc-uri={doc-uri}")
  ;; TODO: try to get info directly if sym not found
  (let [[tgt-scope tgt-ns tgt-sym] (get-scope/ns/sym full-sym)
        current-mod (uri->mod root-uri doc-uri)
        eq-sym-or-ns?
        #%(let [[load-scope load-ns load-sym]
                (get-scope/ns/sym (:sym %1))]
            (or (= tgt-sym load-sym)))
        matches (->> ($GLOBAL.get-$SYMS) .values list
                     (filter eq-sym-or-ns?)
                     ;; TODO: ???
                     (sorted :key #%(if (= (:uri %1) doc-uri)
                                      1 2))
                     tuple)]
    (if (> (count matches) 0)
      (get ($GLOBAL.get-$SYMS) (:sym (first matches)))
      None)))

(defn get-candidates
  [prefix root-uri doc-uri]
  r"
  TODO: update doc
  Get all candidates supposed by prefix from all scopes.
  (globals, locals, builtins, and macros)

    Example:
    ```hy
    (get-candidates \"de\")
    ; => #({\"scope\" \"builtin\"
    ; \"type\" <class 'builtin_function_or_method'>
    ; \"sym\" \"delattr\"})
    ```
    "
    (logger.debug f"get-candidates: prefix={prefix}")
    (let [editing-mod (uri->mod root-uri doc-uri)
          splitted (.split prefix ".")
          module-or-class (module-or-class? splitted)
          sym-prefix (if module-or-class
                       (last splitted)
                       prefix)
          _ (when (and module-or-class
                       (not sym-prefix))
              (load-pymodule-syms! {"name" module-or-class}
                                   doc-uri False))
          filter-fn
          #%(let [full-sym (first %1)
                  sym (get-sym full-sym)
                  scope (-> %1 second (get "scope"))]
              (and (in scope [editing-mod
                              "(builtin)"
                              "(hykwd)"
                              "(sysenv)"
                              "(venv)"
                              module-or-class])
                   (or (.startswith (get-ns full-sym) module-or-class)
                       (.startswith scope module-or-class))
                   (.startswith sym sym-prefix)))]
      (logger.debug f"editing-mod={editing-mod}, module-or-class={module-or-class}, sym-prefix={sym-prefix}")
      (->> ($GLOBAL.get-$SYMS) .items
           (filter filter-fn)
           tuple)))

(defn get-matches
  [tgt-full-sym root-uri doc-uri]
  "TODO: doc"
  ;; TODO: bugfix
  (logger.debug f"get-matches tgt-sym={tgt-full-sym}")
  (let [tgt-scope (uri->mod root-uri doc-uri)
        tgt-sym (get-sym tgt-full-sym)
        _ (logger.debug f"\ttgt-scope={tgt-scope}, tgt-sym={tgt-sym}")
        filter-fn
        #%(let [[loaded-scope loaded-ns loaded-sym]
                (get-scope/ns/sym (first %1))
                loaded-scope (-> %1 second (get "scope"))]
            (or (= loaded-scope tgt-full-sym)
                (and (= tgt-scope loaded-scope)
                     (= loaded-sym tgt-sym))
                (= loaded-sym tgt-sym)))]
    (->> ($GLOBAL.get-$SYMS) .items
         ;; TODO: jump by module name(e.g. sym-tgt=hyrule.collections)
         (filter filter-fn)
         tuple)))

(defn get-symbols [root-uri doc-uri]
  (let [tgt-scope (uri->mod root-uri doc-uri)]
    (setv symbols (valfilter 
      (fn [symbol] 
        (guard (= (get symbol "uri") doc-uri)
          (return False))

        (setv type-info (get symbol "type"))
        (guard (isinstance type-info dict)
	         (return False))
        (return (in (try-else (get type-info "type") "") ["defclass" "defn" "defmain" "meth"])))
    ($GLOBAL.get-$SYMS))))
    
    ; FIXME: We sometimes see the same symbol twice: Once in a class definition and once outside of it.
    ; E.g., "\\.None\\LLMService.run-tasks" and "\\.None\\run-tasks"
    ; Instead of fixing the core issue that leads to this, we decide to try and remove duplicates here.
    (setv unique-names {})
    (for [symbol (symbols.items)]
      (setv name (first symbol)
            data (second symbol)
            pos (get data "pos"))

      ; When we haven't seen the symbol, yet, we mark it as seen.
      (when (not-in pos unique-names)
        (assoc unique-names pos name)
        (continue))

      ; Otherwise, we only add the new symbol if its name is longer than the
      ; one we have already seen.
      (setv existing-name (get unique-names pos))
      (when (< (len existing-name) (len name))
        ; We found a more specific symbol definition so we overwrite the existing one
        (assoc unique-names pos name)))

    ; Collect the symbols belonging to the unique names
    (dfor name (unique-names.values) 
      name (get symbols name)))
