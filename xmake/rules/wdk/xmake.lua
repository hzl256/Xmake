--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: environment
rule("wdk.env")

    -- on load
    on_load(function (target)
        import("detect.sdks.find_wdk")
        if not target:data("wdk") then
            target:data_set("wdk", assert(find_wdk(nil, {verbose = true}), "WDK not found!"))
        end
    end)

    -- clean files
    after_clean(function (target)
        for _, file in ipairs(target:data("wdk.cleanfiles")) do
            os.rm(file)
        end
        target:data_set("wdk.cleanfiles", nil)
    end)

-- define rule: *.inf
rule("wdk.inf")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".inf", ".inx")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get stampinf
        local stampinf = path.join(target:data("wdk").bindir, arch, is_host("windows") and "stampinf.exe" or "stampinf")
        assert(stampinf and os.isexec(stampinf), "stampinf not found!")
        
        -- save uic
        target:data_set("wdk.stampinf", stampinf)
    end)

    -- on build file
    on_build_file(function (target, sourcefile)

        -- copy file to target directory
        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. ".inf")
        os.cp(sourcefile, targetfile)

        -- get stampinf
        local stampinf = target:data("wdk.stampinf")

        -- update the timestamp
        os.vrunv(stampinf, {"-d", "*", "-a", is_arch("x64") and "arm64" or "x86", "-v", "*", "-f", targetfile}, {wildcards = false})

        -- add clean files
        target:data_add("wdk.cleanfiles", targetfile)
    end)

-- define rule: tracewpp
rule("wdk.tracewpp")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get tracewpp
        local tracewpp = path.join(target:data("wdk").bindir, arch, is_host("windows") and "tracewpp.exe" or "tracewpp")
        assert(tracewpp and os.isexec(tracewpp), "tracewpp not found!")
        
        -- save uic
        target:data_set("wdk.tracewpp", tracewpp)
    end)

    -- before build file
    before_build_file(function (target, sourcefile)

        -- get tracewpp
        local tracewpp = target:data("wdk.tracewpp")

        print(tracewpp, sourcefile)

        -- update the timestamp
--        os.vrunv(tracewpp, {"-d", "*", "-a", is_arch("x64") and "arm64" or "x86", "-v", "*", "-f", targetfile}, {wildcards = false})

        -- add clean files
--        target:data_add("wdk.cleanfiles", targetfile)
    end)

-- define rule: umdf driver
rule("wdk.umdf.driver")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "shared", mode = "umdf"})
    end)

-- define rule: umdf binary
rule("wdk.umdf.binary")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", mode = "umdf"})
    end)

-- define rule: kmdf driver
rule("wdk.kmdf.driver")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "shared", mode = "kmdf"})
    end)

-- define rule: kmdf binary
rule("wdk.kmdf.binary")

    -- add rules
    add_deps("wdk.inf")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", mode = "kmdf"})
    end)
