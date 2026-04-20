"""CC 工具链 Module Extension

提供简洁的 API 来配置 Nixpkgs CC 工具链。

使用方式：

    cc = use_extension("@rules_nixpkgs_cc//extensions:cc.bzl", "cc_toolchain")
    cc.configure(repo = "@nixpkgs")
    use_repo(cc, "nixpkgs_cc", "nixpkgs_cc_info", "nixpkgs_cc_toolchains")
    register_toolchains("@nixpkgs_cc_toolchains//:all")
"""

load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")

def _cc_toolchain_impl(module_ctx):
    """实现 CC 工具链配置"""
    root_deps = []

    for mod in module_ctx.modules:
        for tag in mod.tags.configure:
            name = tag.name

            # 处理 repository 参数
            repository = None
            if tag.repo:
                repository = tag.repo

            nixpkgs_cc_configure(
                name = name,
                repository = repository,
                attribute_path = tag.attribute_path or "",
                nix_file_content = tag.nix_file_content or "",
                nixopts = list(tag.nixopts) if tag.nixopts else [],
                quiet = tag.quiet,
                fail_not_supported = tag.fail_not_supported,
                register = False,
                cc_lang = tag.cc_lang,
                cc_std = tag.cc_std,
            )

            root_deps.extend([
                name,
                "{}_info".format(name),
                "{}_toolchains".format(name),
            ])

    return module_ctx.extension_metadata(
        root_module_direct_deps = root_deps,
        root_module_direct_dev_deps = [],
    )

_configure_tag = tag_class(
    attrs = {
        "name": attr.string(default = "nixpkgs_cc"),
        "repo": attr.label(doc = "Nixpkgs 仓库标签，如 '@nixpkgs'"),
        "attribute_path": attr.string(),
        "nix_file_content": attr.string(),
        "nixopts": attr.string_list(),
        "quiet": attr.bool(default = False),
        "fail_not_supported": attr.bool(default = True),
        "cc_lang": attr.string(default = "c++"),
        "cc_std": attr.string(default = "c++17"),
    },
)

cc_toolchain = module_extension(
    implementation = _cc_toolchain_impl,
    tag_classes = {
        "configure": _configure_tag,
    },
)