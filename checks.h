/*******************************************************************************
 *
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *    Sierra Wireless - initial API and implementation
 *
 ******************************************************************************/

#ifndef CHECKS_H
#define CHECKS_H

#ifdef __cplusplus
#include <lua.hpp>
#else
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#endif


#ifndef CHECKS_API
#define CHECKS_API extern
#endif


#ifdef __cplusplus
extern "C" {
#endif
CHECKS_API int luaopen_checks( lua_State *L);
#ifdef __cplusplus
}
#endif

#endif

