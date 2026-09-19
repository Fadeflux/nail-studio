-- ============================================================
--  💅 Mon Atelier Nail Art — schéma Supabase
--  Synchronisation privée : 1 document JSON par compte,
--  protégé par Row Level Security (owner_id = auth.uid()).
--  Script REJOUABLE (idempotent) : on peut le relancer sans risque.
-- ============================================================

-- Table d'état : une seule ligne par personne connectée.
create table if not exists public.nail_state (
  owner_id   uuid primary key references auth.users(id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Active la sécurité par ligne : personne ne voit la ligne d'un autre.
alter table public.nail_state enable row level security;

-- Chaque personne ne peut LIRE que sa propre ligne.
drop policy if exists nail_state_select_own on public.nail_state;
create policy nail_state_select_own on public.nail_state
  for select using (owner_id = auth.uid());

-- ...INSÉRER que sa propre ligne.
drop policy if exists nail_state_insert_own on public.nail_state;
create policy nail_state_insert_own on public.nail_state
  for insert with check (owner_id = auth.uid());

-- ...METTRE À JOUR que sa propre ligne.
drop policy if exists nail_state_update_own on public.nail_state;
create policy nail_state_update_own on public.nail_state
  for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- ...SUPPRIMER que sa propre ligne.
drop policy if exists nail_state_delete_own on public.nail_state;
create policy nail_state_delete_own on public.nail_state
  for delete using (owner_id = auth.uid());

-- Horodatage automatique à chaque modification.
create or replace function public.nail_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists nail_state_touch on public.nail_state;
create trigger nail_state_touch
  before update on public.nail_state
  for each row execute function public.nail_touch();

-- Ceinture + bretelles : le rôle anonyme (non connecté) n'a AUCUN accès ;
-- seuls les comptes authentifiés agissent, et la RLS les limite à leur ligne.
revoke all on public.nail_state from anon;
grant select, insert, update, delete on public.nail_state to authenticated;
revoke execute on function public.nail_touch() from public, anon;

-- ============================================================
--  Fin du schéma. Base prête pour la synchronisation privée. 🎀
-- ============================================================
