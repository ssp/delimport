/*
 * Copyright 2002-2003 Miro Jurisic, All rights reserved.
 * See <http://creativecommons.org/licenses/by/1.0/> for license terms
 */

#import "NSDataAdditions.h"

#import <fcntl.h>
#import <unistd.h>

#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <mach-o/stab.h>

#import "Logging.h"


extern "C" {
    NSData* cononicalFormOfExecutable(NSString *path) {
        NSMutableData *result = nil;
        //NSMutableArray *sections = [NSMutableArray array], *relocSections = [NSMutableArray array];
        NSMutableArray *symtabs = [NSMutableArray array];
        int input, sizeRead;
        mach_header header;
        
        input = open([path UTF8String], O_RDONLY, 0);
        
        if (input == -1) {
            PDEBUG(@"open(\"%@\", O_RDONLY, 0) returned error #%d (%s).\n", path, errno, strerror(errno));
            return nil;
        }
        
        // Get the mach header off the stream
        sizeRead = read(input, (char*)&header, sizeof(mach_header));
            
        if (sizeof(mach_header) != sizeRead) {
            PCONSOLE(@"Unable to read Mach header for \"%@\".\n", path);
            PDEBUG(@"read(%d, %p, %d) [for \"%@\"] returned %d (errno = #%d [%s]).\n", input, &header, sizeof(mach_header), path, sizeRead, errno, strerror(errno));
            return nil;
        }
        
        // Check that this is a Mach-O executable
        if (header.magic != MH_MAGIC) {
            PCONSOLE(@"\"%@\" is not a valid Mach-O file (invalid header magic, %x [%x expected]).\n", path, header.magic, MH_MAGIC);
            return nil;
        }
        
        if (header.filetype != MH_EXECUTE) {
            PCONSOLE(@"\"%@\" is not a Mach-O executable (file type is %d, not %d [MH_EXECUTE]).\n", path, header.filetype, MH_EXECUTE);
            return nil;
        }
        
        unsigned long currentSize = 0, removedCommands = 0, removedBytes = 0;
        load_command command;
        unsigned long dataSize;
        
        result = [NSMutableData data];
        
        for (unsigned long cmd = 0; cmd < header.ncmds; ++cmd) {
            readSize = read(input, (char*)&command, sizeof(load_command));
            
            if (sizeof(load_command) != readSize) {
                PCONSOLE(@"Unable to read command #%d from \"%@\".", cmd, path);
                PDEBUG(@"read(%d, %p, %d) returned %d (errno = #%d [%s]).\n", input, &command, sizeof(load_command), readSize, errno, strerror(errno));
                return nil;
            }
            
            // Length of command data
            dataSize = command.cmdsize;
            dataSize -= sizeof(load_command);
            
            switch (command.cmd) {
                case LC_PREBIND_CKSUM: // Skip these two commands completely
                case LC_PREBOUND_DYLIB:
                    if (-1 == lseek(input, dataSize, SEEK_CUR)) {
                        PCONSOLE(@"Unable to skip prebinding information in \"%@\", error #%d (%s).", path, errno, strerror(errno));
                        PDEBUG(@"lseek(%d, %d, SEEK_CUR) [for \"%@\"] returned error #%d (%s).\n", input, dataSize, path, errno, strerror(errno));
                        return nil;
                    } else {
                        ++removedCommands;
                        removedBytes += command.cmdsize;
                    }
                    
                    break;
                default: // Copy everything else to output
                    char buffer[1024];
                    int readSize;
                    
                    [result appendBytes:(char*)&command length:sizeof(load_command)];
                    
                    while (dataSize > 0) {
                        readSize = (dataSize > 1024) ? 1024 : dataSize;
                        
                        if (readSize != read(input, buffer, readSize)) {
                            PCONSOLE(@"Unable to read data from \"%@\", error #%d (%s).", path, errno, strerror(errno));
                            PDEBUG(@"read(%d, %p, %d) [for \"%@\"] returned error #%d (%s).\n", input, buffer, readSize, path, errno, strerror(errno));
                            return nil;
                        }
                        
                        [result appendBytes:buffer length:readSize];
                        dataSize -= readSize;
                    }
            };
            
            currentSize += command.cmdsize;
        }
        
        if (currentSize != header.sizeofcmds) {
            PCONSOLE(@"Header length in \"%@\" of %d differs from file length %d.\n", path, header.sizeofcmds, currentSize);
            return nil;
        }
        
        header.ncmds -= removedCommands;
        header.sizeofcmds -= removedBytes;
        header.flags &= ~MH_PREBOUND;
        
        // Always remove data in page-sized blocks
        unsigned long padBytes = removedBytes % 0x1000;
        removedBytes -= padBytes;
        
        char *rawData = (char*)[result mutableBytes];
        long offset = 0;
        load_command *commandPtr;
        segment_command *segmentCommandPtr;
        section *sectionDataPtr;
        symtab_command *symtabCommandPtr;
        dysymtab_command *dysymtabCommandPtr;
        twolevel_hints_command *twolevelHintsCommandPtr;
        
        result = [NSMutableData dataWithBytes:(char*)&header length:sizeof(mach_header)];
        
        // Copy the saved commands and adjust their offsets
        for (unsigned long cmd = 0; cmd < header.ncmds; ++cmd) {
            commandPtr = (load_command*)(rawData + offset);
            offset += sizeof(load_command);
            
            // Length of command data
            dataSize = commandPtr->cmdsize - sizeof(load_command);
            
            switch (commandPtr->cmd) {
                case LC_SEGMENT:
                    segmentCommandPtr = (segment_command*)(rawData + offset - sizeof(load_command));
                    offset += sizeof(segment_command) - sizeof(load_command);
                    
                    if (segmentCommandPtr->fileoff > 0) {
                        // If the segment does not start at
                        // the beginning of the file, then 
                        // its beginning will have shifted
                        segmentCommandPtr->fileoff -= removedBytes;
                    } else if (segmentCommandPtr->filesize > 0) {
                        // If the segment is at the beginning of 
                        // the file and is not zero-length, then
                        // it includes load commands, and
                        // needs to be shortened
                        segmentCommandPtr->filesize -= removedBytes;
                        segmentCommandPtr->vmsize -= removedBytes;
                    }
                        
                    [result appendBytes:(char*)segmentCommandPtr length:sizeof(segment_command)];
                    
                    for (unsigned long sectionIndex = 0; sectionIndex < segmentCommandPtr->nsects; ++sectionIndex) {
                        sectionDataPtr = (section*)(rawData + offset);
                        offset += sizeof(section);
                        
                        //[sections addObject:[NSValue valueWithPointer:sectionDataPtr]];
                        
                        if ((sectionDataPtr->flags & SECTION_TYPE) != S_ZEROFILL) { // Zero-filled sections have no on-disk representation
                            if (sectionDataPtr->offset > 0) {
                                // If a section does not start at 
                                // the beginning, it will have shifted
                                sectionDataPtr->offset -= removedBytes;
                            } else if (sectionDataPtr->size > 0) {
                                // If it starts at the beginning, and 
                                // is not empty, it will have shrunk
                                sectionDataPtr->size -= removedBytes;
                            }
                            
                            if (sectionDataPtr->reloff > 0) {
                                sectionDataPtr->reloff -= removedBytes;
                                
                                /*if ((sectionDataPtr->flags & (S_ATTR_LOC_RELOC | S_ATTR_EXT_RELOC)) && (sectionDataPtr->nreloc > 0)) { // FLAG - remember to remove LOC or EXT as necessary, once it's determined which types need to be manipulated
                                    [relocSections addObject:[NSValue valueWithPointer:sectionDataPtr]];
                                }*/
                            }
                        }
                        
                        [result appendBytes:(char*)sectionDataPtr length:sizeof(section)];
                    }
                        
                    break;
                case LC_SYMTAB:
                    symtabCommandPtr = (symtab_command*)(rawData + offset - sizeof(load_command));
                    offset += sizeof(symtab_command) - sizeof(load_command);

                    [symtabs addObject:[NSValue valueWithPointer:symtabCommandPtr]];
                    
                    // Adjust the offsets
                    if (symtabCommandPtr->symoff > 0) {
                        symtabCommandPtr->symoff -= removedBytes;
                    }
                        
                    if (symtabCommandPtr->stroff > 0) {
                        symtabCommandPtr->stroff -= removedBytes;
                    }
                    
                    [result appendBytes:(char*)symtabCommandPtr length:sizeof(symtab_command)];
                    
                    break;
                case LC_DYSYMTAB:
                    dysymtabCommandPtr = (dysymtab_command*)(rawData + offset - sizeof(load_command));
                    offset += sizeof(dysymtab_command) - sizeof(load_command);

                    // Adjust the offsets
                    if (dysymtabCommandPtr->tocoff > 0) {
                        dysymtabCommandPtr->tocoff -= removedBytes;
                    }
                        
                    if (dysymtabCommandPtr->modtaboff > 0) {
                        dysymtabCommandPtr->modtaboff -= removedBytes;
                    }
                        
                    if (dysymtabCommandPtr->extrefsymoff > 0) {
                        dysymtabCommandPtr->extrefsymoff -= removedBytes;
                    }
                        
                    if (dysymtabCommandPtr->indirectsymoff > 0) {
                        dysymtabCommandPtr->indirectsymoff -= removedBytes;
                    }
                        
                    if (dysymtabCommandPtr->extreloff > 0) {
                        dysymtabCommandPtr->extreloff -= removedBytes;
                    }
                        
                    if (dysymtabCommandPtr->locreloff > 0) {
                        dysymtabCommandPtr->locreloff -= removedBytes;
                    }
                        
                    [result appendBytes:(char*)dysymtabCommandPtr length:sizeof(dysymtab_command)];
                    
                    break;
                case LC_PREBOUND_DYLIB:
                    PCONSOLE(@"LC_PREBOUND_DYLIB found in \"%@\".", path);
                    return nil; break;
                case LC_TWOLEVEL_HINTS:
                    twolevelHintsCommandPtr = (twolevel_hints_command*)(rawData + offset - sizeof(load_command));
                    offset += sizeof(twolevel_hints_command) - sizeof(load_command);

                    // Adjust the offsets
                    if (twolevelHintsCommandPtr->offset > 0) {
                        twolevelHintsCommandPtr->offset -= removedBytes;
                    }
                        
                    [result appendBytes:(char*)twolevelHintsCommandPtr length:sizeof(twolevel_hints_command)];
                    
                    break;
                case LC_PREBIND_CKSUM:
                    PCONSOLE(@"LC_PREBIND_CKSUM found in \"%@\".", path);
                    return nil; break;
                    // These load commands can be copied unchanged
                case LC_UNIXTHREAD:
                case LC_LOAD_DYLIB:
                case LC_LOAD_DYLINKER:
                    [result appendBytes:(char*)commandPtr length:sizeof(load_command)];
                    
                    [result appendBytes:(rawData + offset) length:dataSize];
                    offset += dataSize;
                    
                    break;
                case LC_SYMSEG:
                case LC_THREAD:
                case LC_LOADFVMLIB:
                case LC_IDFVMLIB:
                case LC_IDENT:
                case LC_FVMFILE:
                case LC_PREPAGE:
                case LC_ID_DYLIB:
                case LC_ID_DYLINKER:
                case LC_ROUTINES:
                case LC_SUB_FRAMEWORK:
                case LC_SUB_UMBRELLA:
                case LC_SUB_CLIENT:
                case LC_SUB_LIBRARY:
                case LC_LOAD_WEAK_DYLIB:
                    PCONSOLE(@"An unimplemented load command, %d, was encountered in \"%@\".", commandPtr->cmd, path);
                    return nil; break;
                default:
                    PCONSOLE(@"An unknown load command, %d, was encountered in \"%@\".", commandPtr->cmd, path);
                    return nil;
            };
        }
        
        [result increaseLengthBy:padBytes]; // Zero-fills extra bytes
        
        char buffer[1024];
        int readSize = read(input, buffer, 1024);
        
        while (readSize > 0) {
            [result appendBytes:buffer length:readSize];
            
            readSize = read(input, buffer, 1024);
        }
        
        if (removedBytes > 0) {
            rawData = (char*)[result mutableBytes];
            
            NSEnumerator *enumerator = [symtabs objectEnumerator];
            NSValue *current;
            struct nlist *symbol;
            
            while (current = [enumerator nextObject]) {
                symtabCommandPtr = (symtab_command*)[current pointerValue];
                
                for (unsigned long i = 0; i < symtabCommandPtr->nsyms; ++i) {
                    symbol = (struct nlist*)(rawData + symtabCommandPtr->symoff + (sizeof(struct nlist) * i));
                    
                    if (symbol->n_type & N_STAB) {
                        switch (symbol->n_type) {
                            case N_GSYM: /* global symbol: name,,NO_SECT,type,0 */
                            case N_FNAME: /* procedure name (f77 kludge): name,,NO_SECT,0,0 */
                            case N_RSYM: /* register sym: name,,NO_SECT,type,register */
                            case N_PARAMS: /* compiler parameters: name,,NO_SECT,0,0 */
                            case N_VERSION: /* compiler version: name,,NO_SECT,0,0 */
                            case N_OLEVEL: /* compiler -O level: name,,NO_SECT,0,0 */
                            case N_EINCL: /* include file end: name,,NO_SECT,0,0 */
                            case N_BCOMM: /* begin common: name,,NO_SECT,0,0 */
                            case N_ECOMM: /* end common: name,,n_sect,0,0 */
                                // These should all be NULL anyway, so there's nothing to correct
                                break;
                                
                                // What on earth is "sum"?  These don't appear to ever actually occur in an executable...
                            case N_BINCL: /* include file beginning: name,,NO_SECT,0,sum */
                            case N_EXCL: /* deleted include file: name,,NO_SECT,0,sum */
                                PCONSOLE(@"Encountered N_BINCL or N_EXCL (0x%x) in \"%@\" - not sure how to handle them, with an apparent 'sum' of 0x%x (%d).\n", symbol->n_type, path, symbol->n_value, symbol->n_value);
                                break;
                                
                                // What are these offset from; the start of the file, or their relevant sections or somesuch?  Whatever they are, they appear to be mostly 0, an when they're not they are too small to be absolute file offsets
                            case N_LSYM: /* local sym: name,,NO_SECT,type,offset */
                            case N_PSYM: /* parameter: name,,NO_SECT,type,offset */
                                //PCONSOLE(@"Encountered N_LSYM or N_PSYM (0x%x) in \"%@\" - not sure how to handle them, with an apparent offset of 0x%x (%d).\n", symbol->n_type, path, symbol->n_value, symbol->n_value);
                                break;
                                
                                // What are these?
                            case N_LENG: /* second stab entry with length information */
                            case N_OPT: /* emitted with gcc2_compiled and in gcc source */
                            case N_PC: /* global pascal symbol: name,,NO_SECT,subtype,line */
                                PCONSOLE(@"Encountered N_LENG, N_OPT or N_PC (0x%x) in \"%@\" - not sure how to handle them, with an apparent offset of 0x%x (%d).\n", symbol->n_type, path, symbol->n_value, symbol->n_value);
                                break;
                                
                                // While N_FUN specifies a section number and address, there are cases where n_sect == 0, which are presumably special cases of some sort.  Need to test for them.
                            case N_FUN: /* procedure: name,,n_sect,linenumber,address */
                                if (symbol->n_type == NO_SECT) {
                                    break;
                                } // else fall through
                                
                            case N_STSYM: /* static symbol: name,,n_sect,type,address */
                            case N_LCSYM: /* .lcomm symbol: name,,n_sect,type,address */
                            case N_BNSYM: /* begin nsect sym: 0,,n_sect,0,address */
                            case N_SLINE: /* src line: 0,,n_sect,linenumber,address */
                            case N_ENSYM: /* end nsect sym: 0,,n_sect,0,address */
                            case N_SO: /* source file name: name,,n_sect,0,address */
                            case N_SOL: /* #included file name: name,,n_sect,0,address */
                            case N_ENTRY: /* alternate entry: name,,n_sect,linenumber,address */
                            case N_LBRAC: /* left bracket: 0,,NO_SECT,nesting level,address */
                            case N_RBRAC: /* right bracket: 0,,NO_SECT,nesting level,address */
                            case N_ECOML: /* end common (local name): 0,,n_sect,0,address */
                            case N_SSYM: /* structure elt: name,,NO_SECT,type,struct_offset */
                                symbol->n_value -= removedBytes; // Fix the offsets
                                break;
                                
                            default:
                                PCONSOLE(@"Encountered unknown STAB type (0x%x) in \"%@\" - ignoring [with value of 0x%x (%d)].\n", symbol->n_type, path, symbol->n_value, symbol->n_value);
                        }
                    } else {
                        if ((symbol->n_type & N_TYPE) == N_SECT) {
                            symbol->n_value -= removedBytes; // Fix the offsets
                        }
                    }
                }
            }
            
            /*NSEnumerator *enumerator = [relocSections objectEnumerator];
            NSValue *current;
            relocation_info *relocPtr;
            scattered_relocation_info *scatteredPtr;
            char *currentSection;
            section *adjustSection;
            
            rawData = [result mutableBytes];
            
            assert(sizeof(relocation_info) == sizeof(scattered_relocation_info));
            
            while (current = [enumerator nextObject]) {
                sectionDataPtr = (section*)[current pointerValue];
                
                currentSection = rawData + sectionDataPtr->offset;
                
                for (i = 0; i < sectionDataPtr->nreloc; ++i) {
                    relocPtr = (relocation_info*)(rawData + sectionDataPtr->reloff + (i * sizeof(relocation_info)));
                    
                    if (relocPtr->r_address & R_SCATTERED) {
                        scatteredPtr = (scattered_relocation_info*)relocPtr;
                        
                        // FLAG - to be completed
                    } else {
                        if ((relocPtr->r_extern == 0) && (relocPtr->r_pcrel == 0)) { // We only need to adjust the case where it's an index into a section, not the symbol table, and also only where it's an absolute address, not a PC-relative one
                            if (relocPtr->r_symbolnum != R_ABS) { // No further relocation required... or somesuch
                                if (relocPtr->r_symbolnum > [sections count]) { // Sections start at 1
                                    PCONSOLE(@"Encountered a reference to an invalid section (%d, with %d sections) in the relocation tables (in \"%@\").\n", relocPtr->r_symbolnum, [sections count], path);
                                    return nil;
                                }
                                
                                adjustSection = (section*)[[sections objectAtIndex:(relocPtr->r_symbolnum - 1)] pointerValue];
                                
                                switch (relocPtr->r_type) {
                                    case PPC_RELOC_PAIR: // The second relocation entry of a pair. A PPC_RELOC_PAIR entry must follow each of the other relocation entry types, except for PPC_RELOC_VANILLA, PPC_RELOC_BR14, PPC_RELOC_BR24, and PPC_RELOC_PB_LA_PTR.
                                        
                                    case PPC_RELOC_BR14: // The instruction contains a 14-bit branch displacement.
                                        
                                    case PPC_RELOC_BR24: // The instruction contains a 24-bit branch displacement.
                                        
                                    case PPC_RELOC_HI16: // The instruction contains the high 16 bits of a relocatable expression. The next relocation entry must be a PPC_RELOC_PAIR specifying the low 16 bits of the expression in the low 16 bits of the r_value field.
                                        
                                    case PPC_RELOC_LO16: // The instruction contains the low 16 bits of an address. The next relocation entry must be a PPC_RELOC_PAIR specifying the high 16 bits of the expression in the low (not the high) 16 bits of the r_value field.
                                        
                                    case PPC_RELOC_HA16: // Same as the PPC_RELOC_HI16 except the low 16 bits and the high 16 bits are added together with the low 16 bits sign-extended first. This means if bit 15 of the low 16 bits is set, the high 16 bits stored in the instruction will be adjusted.
                                        
                                    case PPC_RELOC_LO14: // Same as PPC_RELOC_LO16 except that the low 2 bits are not stored in the CPU instruction and are always zero. PPC_RELOC_LO14 is used in 64-bit load/store instructions.
                                        
                                    case PPC_RELOC_SECTDIFF: // A relocation entry for an item that contains the difference of two section addresses. This is generally used for position-independent code generation. PPC_RELOC_SECTDIFF contains the address from which to subtract; it must be followed by a PPC_RELOC_PAIR containing the section address to subtract.
                                        
                                    case PPC_RELOC_PB_LA_PTR: // A relocation entry for a prebound lazy pointer. This is always a scattered relocation entry. The r_value field contains the non-prebound value of the lazy pointer.
                                        
                                    case PPC_RELOC_HI16_SECTDIFF: // Section difference form of PPC_RELOC_HI16.
                                        
                                    case PPC_RELOC_LO16_SECTDIFF: // Section difference form of PPC_RELOC_LO16.
                                        
                                    case PPC_RELOC_HA16_SECTDIFF: // Section difference form of PPC_RELOC_HA16.
                                        
                                    case PPC_RELOC_JBSR: // A relocation entry for the assembler synthetic opcode jbsr, which is a 24-bit branch-and-link instruction using a branch island. The branch displacement is assembled to the branch island address and the relocation entry indicates the actual target symbol. If the linker can make the branch reach the actual target symbol that is done. Otherwise, the branch is relocated to the branch island.
                                }
                                switch (relocPtr->r_length) {
                                    case 0: // 1 byte
                                        
                                    case 1: // 2 bytes
                                        
                                    case 2: // 4 bytes
                                        
                                    default:
                                        PCONSOLE(@"Encountered a relocation entry longer than 4 bytes (%d) in \"%@\"; 8 byte and higher orders are not yet supported.\n", relocPtr->r_length, path);
                                        return nil;
                                }
                            }
                        }
                    }
                }
            }*/
        }
        
        return result;
    }
}
