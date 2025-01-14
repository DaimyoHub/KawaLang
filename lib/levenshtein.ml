open Symbol
open Environment

let get_minimal_name distance_table first_name =
  let _, n =
    Hashtbl.fold
      (fun dist name min ->
        let min_dist, _ = min in
        let new_min =
          if dist < min_dist || min_dist = 0 then (dist, name) else min
        in
        new_min)
      distance_table (0, first_name)
  in
  n

(*
 * On calcule la distance de Levenshtein de dst par rapport à src.
 * Paradigme : programmation dynamique (bottom-up)
 *)
let compute_distance src dst =
  let lsrc = String.length src in
  let ldst = String.length dst in

  let mat = Array.make_matrix (lsrc + 1) (ldst + 1) 0 in
  for i = 0 to lsrc do
    mat.(i).(0) <- i
  done;

  for j = 0 to ldst do
    mat.(0).(j) <- j
  done;

  for i = 1 to lsrc do
    for j = 1 to ldst do
      let cost = if src.[i - 1] = dst.[j - 1] then 0 else 1 in
      let min1 = min (mat.(i - 1).(j) + 1) (mat.(i).(j - 1) + 1) in
      mat.(i).(j) <- min min1 (mat.(i - 1).(j - 1) + cost)
    done
  done;

  mat.(lsrc).(ldst)

let make_distance_table names name =
  List.fold_left
    (fun acc x ->
      let dist = compute_distance name x in
      Hashtbl.add acc dist x;
      acc)
    (Hashtbl.create 5) names

let find_nearest_coherent_symbol env symbol =
  let name_table_ref = ref [] in
  (* Yes, it's definitely ugly, but I must finish the project soon *)
  Env.iter
    (fun _ v ->
      let (Sym name) = v.sym in
      name_table_ref := name :: !name_table_ref)
    env;
  let (Sym name) = symbol in
  let distance_table = make_distance_table !name_table_ref name in
  Sym (get_minimal_name distance_table name)
