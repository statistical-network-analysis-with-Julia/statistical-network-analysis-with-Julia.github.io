const ORG = "statistical-network-analysis-with-Julia"
const GITHUB = "https://github.com/$ORG"

"""
    hfun_pkg_card(params)

Generate a package card. Usage: {{pkg_card PkgName "Description" "r_pkg"}}
(the third parameter is optional; pass the R package this ports).
"""
function hfun_pkg_card(params)
    length(params) >= 2 || return ""
    name = params[1]
    desc = params[2]
    r_pkg = length(params) >= 3 ? params[3] : ""

    repo_url = "$GITHUB/$(name)"
    doc_url = "https://$ORG.github.io/$(name)/stable/"

    r_note = isnothing(r_pkg) || isempty(r_pkg) ? "" : """<span class="r-port">port of R $(r_pkg)</span>"""

    return """
    <div class="pkg-card">
      <h4><a href="$repo_url">$name</a> <span class="badge-julia">Julia</span></h4>
      <p>$desc</p>
      <div class="links">
        <a href="$repo_url">GitHub</a>
        <a href="$doc_url">Docs</a>
        $r_note
      </div>
    </div>
    """
end

const MONTH = ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]

function getdate(fpath)
    fn = splitext(basename(fpath))[1]
    m = match(r"^(\d{4})-(\d{2})-(\d{2})", fn)
    isnothing(m) && return nothing
    y, mo, d = parse.(Int, m.captures)
    return "$(MONTH[mo]) $d, $y"
end

function hfun_blogposts()
    posts = filter(endswith(".md"), readdir("post"; join=true))
    sort!(posts; rev=true)
    io = IOBuffer()
    println(io, "<ul class=\"post-list\">")
    for p in posts
        fn = splitext(basename(p))[1]
        fn == "index" && continue
        date = getdate(p)
        date_str = isnothing(date) ? "" : """<span class="post-date">$date</span>"""
        title_match = match(r"^@def title\s*=\s*\"(.+?)\"", read(p, String))
        if isnothing(title_match)
            title_match = match(r"title\s*=\s*\"(.+?)\"", read(p, String))
        end
        title = isnothing(title_match) ? fn : title_match[1]
        println(io, "<li>$(date_str)<a href=\"/post/$fn/\">$title</a></li>")
    end
    println(io, "</ul>")
    return String(take!(io))
end

function hfun_post_date()
    fpath = locvar("fd_rpath")
    date = getdate(fpath)
    isnothing(date) && return ""
    return "<p class=\"post-date\">$date</p>"
end
