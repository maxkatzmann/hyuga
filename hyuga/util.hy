(import
  functools [partial]
  hyrule.iterables [coll?])

(defn postwalk [f form]
  "Performs depth-first, post-order traversal of ``form``. Calls ``f`` on
  each sub-form, uses ``f`` 's return value in place of the original.

  Examples:
    ::

       => (import hyrule.contrib.walk [postwalk])
       => (setv trail '([1 2 3] [4 [5 6 [7]]]))
       => (defn walking [x]
       ...   (print \"Walking\" x :sep \"\\n\")
       ...   x)
       => (postwalk walking trail)
       Walking
       1
       Walking
       2
       Walking
       3
       Walking
       hy.models.Expression([
         hy.models.Integer(1),
         hy.models.Integer(2),
         hy.models.Integer(3)])
       Walking
       4
       Walking
       5
       Walking
       6
       Walking
       7
       Walking
       hy.models.Expression([
         hy.models.Integer(7)])
       Walking
       hy.models.Expression([
         hy.models.Integer(5),
         hy.models.Integer(6),
         hy.models.List([
           hy.models.Integer(7)])])
       Walking
       hy.models.Expression([
         hy.models.Integer(4),
         hy.models.List([
           hy.models.Integer(5),
           hy.models.Integer(6),
           hy.models.List([
             hy.models.Integer(7)])])])
       Walking
       hy.models.Expression([
         hy.models.List([
           hy.models.Integer(1),
           hy.models.Integer(2),
           hy.models.Integer(3)]),
         hy.models.List([
           hy.models.Integer(4),
           hy.models.List([
             hy.models.Integer(5),
             hy.models.Integer(6),
             hy.models.List([
               hy.models.Integer(7)])])])])
       '([1 2 3] [4 [5 6 [7]]]))
  "
  (walk (partial postwalk f) f form))


(defn prewalk [f form]
  "Performs depth-first, pre-order traversal of ``form``. Calls ``f`` on
  each sub-form, uses ``f`` 's return value in place of the original.

  Examples:
    ::

       => (import hyrule.contrib.walk [prewalk])
       => (setv trail '([1 2 3] [4 [5 6 [7]]]))
       => (defn walking [x]
       ...  (print \"Walking\" x :sep \"\\n\")
       ...  x)
       => (prewalk walking trail)
       Walking
       hy.models.Expression([
         hy.models.List([
           hy.models.Integer(1),
           hy.models.Integer(2),
           hy.models.Integer(3)]),
         hy.models.List([
           hy.models.Integer(4),
           hy.models.List([
             hy.models.Integer(5),
             hy.models.Integer(6),
             hy.models.List([
               hy.models.Integer(7)])])])])
       Walking
       hy.models.List([
         hy.models.Integer(1),
         hy.models.Integer(2),
         hy.models.Integer(3)])
       Walking
       1
       Walking
       2
       Walking
       3
       Walking
       hy.models.List([
         hy.models.Integer(4),
         hy.models.List([
           hy.models.Integer(5),
           hy.models.Integer(6),
           hy.models.List([
             hy.models.Integer(7)])])])
       Walking
       4
       Walking
       hy.models.List([
         hy.models.Integer(5),
         hy.models.Integer(6),
         hy.models.List([
           hy.models.Integer(7)])])
       Walking
       5
       Walking
       6
       Walking
       hy.models.List([
         hy.models.Integer(7)])
       Walking
       7
       '([1 2 3] [4 [5 6 [7]]])
  "
  (walk (partial prewalk f) (fn [x] x) (f form)))


(defn walk [inner outer form]
  "``walk`` traverses ``form``, an arbitrary data structure. Applies
  ``inner`` to each element of form, building up a data structure of the
  same type.  Applies ``outer`` to the result.

  Examples:
    ::

       => (import hyrule.contrib.walk [walk])
       => (setv a '(a b c d e f))
       => (walk ord (fn [x] x)  a)
       '(97 98 99 100 101 102)

    ::

       => (walk ord (fn [x] (get x 0)) a)
       97
  "
  (cond
    (isinstance form hy.models.Expression)
      (outer (hy.models.Expression (map inner form)))
    (or (isinstance form #(hy.models.Sequence list)))
      ((type form) (outer (hy.models.Expression (map inner form))))
    (coll? form)
      (walk inner outer (list form))
    True
      (outer form)))


(defmacro guard [assignment else]
    (setv _assignment (hy.gensym))
    `(do 
        (setv ~_assignment ~assignment)
        (when (not ~_assignment)
            ~else)))


(defmacro try-else [expression else]
    `(try 
        ~expression
        (except [e Exception]
            ~else)))

(defn read-from-file [file]
    (try-else
        (with [f (open file "rt")]
            (return (.read f)))
        (return None)))
