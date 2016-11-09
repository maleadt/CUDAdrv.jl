# finalizers are run out-of-order disregarding field references between objects (see
# JuliaLang/julia#3067), so we manually need to keep instances alive outside of the object
# fields in order to prevent parent objects getting collected before their children

# NOTE: the Dict is inversed (child => parent), to make the more ccommon track/untrack cheap
const gc_keepalive = Dict{WeakRef,Any}()

function gc_track(parent::ANY, child::ANY)
    ref = WeakRef(child)
    haskey(gc_keepalive, ref) && error("objects can only keep a single parent alive")
    gc_keepalive[ref] = parent
end

function gc_untrack(parent::ANY, child::ANY)
    ref = WeakRef(child)
    haskey(gc_keepalive, ref) || error("track/untrack mismatch")
    gc_keepalive[ref] == parent || error("track/untrack mismatch on parent")
    delete!(gc_keepalive, ref)
end

gc_children(parent::ANY) = filter((k,v) -> v == parent, gc_keepalive)