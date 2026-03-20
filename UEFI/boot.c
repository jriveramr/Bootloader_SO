/*
 * boot.c - Bare-metal UEFI bootloader sin bibliotecas externas
 * Compilado con Clang targeting x86_64-unknown-windows (MS ABI = UEFI ABI)
 */

/* ─── Tipos EFI mínimos ──────────────────────────────────────────────────── */
typedef unsigned char      UINT8;
typedef unsigned short     UINT16;
typedef unsigned int       UINT32;
typedef unsigned long long UINT64;
typedef unsigned short     CHAR16;
typedef void*              EFI_HANDLE;
typedef UINT64             EFI_STATUS;
typedef UINT64             UINTN;

#define EFI_SUCCESS         0ULL
#define EFI_NOT_READY       0x8000000000000006ULL

/* ─── EFI GUID ───────────────────────────────────────────────────────────── */
typedef struct {
    UINT32 Data1;
    UINT16 Data2;
    UINT16 Data3;
    UINT8  Data4[8];
} EFI_GUID;

#define EFI_LOADED_IMAGE_PROTOCOL_GUID \
    { 0x5B1B31A1, 0x9562, 0x11D2,     \
      { 0x8E, 0x3F, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B } }

#define EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID \
    { 0x0964E5B22, 0x6459, 0x11D2,           \
      { 0x8E, 0x39, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B } }

/* ─── EFI Device Path ────────────────────────────────────────────────────── */
typedef struct {
    UINT8 Type;
    UINT8 SubType;
    UINT8 Length[2];
} EFI_DEVICE_PATH_PROTOCOL;

/* ─── EFI File Info ──────────────────────────────────────────────────────── */
#define EFI_FILE_INFO_GUID \
    { 0x09576E92, 0x6D3F, 0x11D2,  \
      { 0x8E, 0x39, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B } }

typedef struct {
    UINT64 Size;
    UINT64 FileSize;
    UINT64 PhysicalSize;
    UINT8  CreateTime[16];
    UINT8  LastAccessTime[16];
    UINT8  ModificationTime[16];
    UINT64 Attribute;
    CHAR16 FileName[1];
} EFI_FILE_INFO;

/* ─── EFI File Protocol ──────────────────────────────────────────────────── */
typedef struct _EFI_FILE_PROTOCOL {
    UINT64 Revision;
    EFI_STATUS (*Open)(
        struct _EFI_FILE_PROTOCOL  *This,
        struct _EFI_FILE_PROTOCOL **NewHandle,
        CHAR16                    *FileName,
        UINT64                     OpenMode,
        UINT64                     Attributes);
    EFI_STATUS (*Close)(
        struct _EFI_FILE_PROTOCOL *This);
    EFI_STATUS (*Delete)(
        struct _EFI_FILE_PROTOCOL *This);
    EFI_STATUS (*Read)(
        struct _EFI_FILE_PROTOCOL *This,
        UINTN                     *BufferSize,
        void                      *Buffer);
    EFI_STATUS (*Write)(
        struct _EFI_FILE_PROTOCOL *This,
        UINTN                     *BufferSize,
        void                      *Buffer);
    EFI_STATUS (*GetPosition)(
        struct _EFI_FILE_PROTOCOL *This,
        UINT64                    *Position);
    EFI_STATUS (*SetPosition)(
        struct _EFI_FILE_PROTOCOL *This,
        UINT64                     Position);
    EFI_STATUS (*GetInfo)(
        struct _EFI_FILE_PROTOCOL *This,
        EFI_GUID                  *InformationType,
        UINTN                     *BufferSize,
        void                      *Buffer);
    EFI_STATUS (*SetInfo)(
        struct _EFI_FILE_PROTOCOL *This,
        EFI_GUID                  *InformationType,
        UINTN                      BufferSize,
        void                      *Buffer);
    EFI_STATUS (*Flush)(
        struct _EFI_FILE_PROTOCOL *This);
} EFI_FILE_PROTOCOL;

#define EFI_FILE_MODE_READ 0x0000000000000001ULL

/* ─── EFI Simple File System Protocol ───────────────────────────────────── */
typedef struct {
    UINT64 Revision;
    EFI_STATUS (*OpenVolume)(
        struct _EFI_SIMPLE_FILE_SYSTEM *This,
        EFI_FILE_PROTOCOL             **Root);
} EFI_SIMPLE_FILE_SYSTEM_PROTOCOL;

/* ─── EFI Loaded Image Protocol ──────────────────────────────────────────── */
typedef struct {
    UINT32                    Revision;
    EFI_HANDLE                ParentHandle;
    void                     *SystemTable;
    EFI_HANDLE                DeviceHandle;
    EFI_DEVICE_PATH_PROTOCOL *FilePath;
    void                     *Reserved;
    UINT32                    LoadOptionsSize;
    void                     *LoadOptions;
    void                     *ImageBase;
    UINT64                    ImageSize;
    UINT32                    ImageCodeType;
    UINT32                    ImageDataType;
    void                     *Unload;
} EFI_LOADED_IMAGE_PROTOCOL;

/* ─── EFI Input Key ──────────────────────────────────────────────────────── */
typedef struct {
    UINT16 ScanCode;
    CHAR16 UnicodeChar;
} EFI_INPUT_KEY;

/* ─── EFI Simple Text Input Protocol ────────────────────────────────────── */
typedef struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
    EFI_STATUS (*Reset)(
        struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This,
        UINT8                                   ExtendedVerification);
    EFI_STATUS (*ReadKeyStroke)(
        struct _EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This,
        EFI_INPUT_KEY                          *Key);
    void *WaitForKey;
} EFI_SIMPLE_TEXT_INPUT_PROTOCOL;

/* ─── EFI Simple Text Output Protocol ───────────────────────────────────── */
typedef struct _SIMPLE_TEXT_OUTPUT_INTERFACE {
    EFI_STATUS (*Reset)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINT8                                 ExtendedVerification);
    EFI_STATUS (*OutputString)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        CHAR16                               *String);
    EFI_STATUS (*TestString)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        CHAR16                               *String);
    EFI_STATUS (*QueryMode)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINTN ModeNumber, UINTN *Columns, UINTN *Rows);
    EFI_STATUS (*SetMode)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINTN                                 ModeNumber);
    EFI_STATUS (*SetAttribute)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINTN                                 Attribute);
    EFI_STATUS (*ClearScreen)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This);
    EFI_STATUS (*SetCursorPosition)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINTN Column, UINTN Row);
    EFI_STATUS (*EnableCursor)(
        struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This,
        UINT8                                 Visible);
    void *Mode;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

/* ─── EFI Boot Services ───────────────────────────────────────────────────── */
typedef struct {
    UINT64 Signature;
    UINT32 Revision;
    UINT32 HeaderSize;
    UINT32 CRC32;
    UINT32 Reserved;

    void *RaiseTPL;
    void *RestoreTPL;
    void *AllocatePages;
    void *FreePages;
    void *GetMemoryMap;

    /* AllocatePool(PoolType, Size, Buffer) */
    EFI_STATUS (*AllocatePool)(
        UINT32  PoolType,
        UINTN   Size,
        void  **Buffer);

    /* FreePool(Buffer) */
    EFI_STATUS (*FreePool)(
        void *Buffer);

    void *CreateEvent;
    void *SetTimer;
    void *WaitForEvent;
    void *SignalEvent;
    void *CloseEvent;
    void *CheckEvent;
    void *InstallProtocolInterface;
    void *ReinstallProtocolInterface;
    void *UninstallProtocolInterface;

    /* HandleProtocol(Handle, Protocol, Interface) */
    EFI_STATUS (*HandleProtocol)(
        EFI_HANDLE  Handle,
        EFI_GUID   *Protocol,
        void      **Interface);

    void *Reserved2;
    void *RegisterProtocolNotify;
    void *LocateHandle;
    void *LocateDevicePath;
    void *InstallConfigurationTable;

    /* LoadImage */
    EFI_STATUS (*LoadImage)(
        UINT8                     BootPolicy,
        EFI_HANDLE                ParentImageHandle,
        EFI_DEVICE_PATH_PROTOCOL *DevicePath,
        void                     *SourceBuffer,
        UINTN                     SourceSize,
        EFI_HANDLE               *ImageHandle);

    /* StartImage */
    EFI_STATUS (*StartImage)(
        EFI_HANDLE  ImageHandle,
        UINTN      *ExitDataSize,
        CHAR16    **ExitData);
} EFI_BOOT_SERVICES;

/* ─── EFI System Table ───────────────────────────────────────────────────── */
typedef struct {
    UINT64                            Signature;
    UINT32                            Revision;
    UINT32                            HeaderSize;
    UINT32                            CRC32;
    UINT32                            Reserved;
    CHAR16                           *FirmwareVendor;
    UINT32                            FirmwareRevision;
    UINT32                            _pad;
    EFI_HANDLE                        ConsoleInHandle;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL   *ConIn;
    EFI_HANDLE                        ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *ConOut;
    EFI_HANDLE                        StandardErrorHandle;
    void                             *StdErr;
    void                             *RuntimeServices;
    EFI_BOOT_SERVICES                *BootServices;
} EFI_SYSTEM_TABLE;

/* ─── Helpers ────────────────────────────────────────────────────────────── */
static void print(EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *out, CHAR16 *s)
{
    out->OutputString(out, s);
}

static void wait_key(EFI_SIMPLE_TEXT_INPUT_PROTOCOL *in)
{
    EFI_INPUT_KEY key;
    in->Reset(in, 0);
    while (in->ReadKeyStroke(in, &key) == EFI_NOT_READY)
        __asm__ volatile ("pause");
}

/* ─── Entry point ────────────────────────────────────────────────────────── */
EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *out = SystemTable->ConOut;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL  *in  = SystemTable->ConIn;
    EFI_BOOT_SERVICES               *bs  = SystemTable->BootServices;

    /* ── 1. Limpiar pantalla ── */
    out->ClearScreen(out);

    /* ── 2. Pantalla de bienvenida ── */
    print(out, L"╔══════════════════════════════════════════╗\r\n");
    print(out, L"║                                          ║\r\n");
    print(out, L"║               My name                    ║\r\n");
    print(out, L"║                                          ║\r\n");
    print(out, L"║  Bienvenido, presiona cualquier tecla    ║\r\n");
    print(out, L"║  para confirmar                          ║\r\n");
    print(out, L"║  Integrantes:                            ║\r\n");
    print(out, L"║    - Jose                                ║\r\n");
    print(out, L"║    - Henry                               ║\r\n");
    print(out, L"║                                          ║\r\n");
    print(out, L"╚══════════════════════════════════════════╝\r\n");
    print(out, L"\r\n");
    print(out, L"  Presiona cualquier tecla para comenzar...\r\n");

    /* ── 3. Esperar confirmacion ── */
    wait_key(in);

    out->ClearScreen(out);
    print(out, L"\r\n  Cargando juego...\r\n");

    /* ── 4. Obtener DeviceHandle de nuestra imagen ── */
    EFI_GUID lip_guid = EFI_LOADED_IMAGE_PROTOCOL_GUID;
    EFI_LOADED_IMAGE_PROTOCOL *loaded_image = 0;

    EFI_STATUS status = bs->HandleProtocol(
        ImageHandle, &lip_guid, (void **)&loaded_image);

    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: HandleProtocol (LoadedImage) fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    /* ── 5. Obtener SimpleFileSystem del mismo volumen ── */
    EFI_GUID sfs_guid = EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID;
    EFI_SIMPLE_FILE_SYSTEM_PROTOCOL *sfs = 0;

    status = bs->HandleProtocol(
        loaded_image->DeviceHandle, &sfs_guid, (void **)&sfs);

    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: HandleProtocol (FileSystem) fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    /* ── 6. Abrir volumen raiz ── */
    EFI_FILE_PROTOCOL *root = 0;
    status = sfs->OpenVolume(sfs, &root);

    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: OpenVolume fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    /* ── 7. Abrir game.efi ── */
    EFI_FILE_PROTOCOL *game_file = 0;
    status = root->Open(
        root, &game_file,
        L"\\EFI\\BOOT\\game.efi",
        EFI_FILE_MODE_READ, 0);

    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: no se pudo abrir game.efi\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    /* ── 8. Obtener tamaño del archivo via GetInfo ── */
    EFI_GUID fi_guid = EFI_FILE_INFO_GUID;
    UINT8    info_buf[256];
    UINTN    info_size = sizeof(info_buf);

    status = game_file->GetInfo(game_file, &fi_guid, &info_size, info_buf);
    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: GetInfo fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    EFI_FILE_INFO *fi   = (EFI_FILE_INFO *)info_buf;
    UINTN          size = (UINTN)fi->FileSize;

    /* ── 9. Allocar buffer y leer el archivo ── */
    void *buf = 0;
    /* PoolType 2 = EfiLoaderData */
    status = bs->AllocatePool(2, size, &buf);
    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: AllocatePool fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    status = game_file->Read(game_file, &size, buf);
    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: Read fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    game_file->Close(game_file);
    root->Close(root);

    /* ── 10. LoadImage desde buffer en memoria ── */
    EFI_HANDLE game_handle = 0;
    status = bs->LoadImage(
        0,            /* BootPolicy                  */
        ImageHandle,  /* ParentHandle                */
        0,            /* DevicePath = NULL (buffer)  */
        buf,          /* SourceBuffer                */
        size,         /* SourceSize                  */
        &game_handle);

    if (status != EFI_SUCCESS) {
        print(out, L"  ERROR: LoadImage fallo\r\n");
        while (1) __asm__ volatile ("hlt");
    }

    /* ── 11. StartImage ── */
    UINTN   exit_data_size = 0;
    CHAR16 *exit_data      = 0;
    bs->StartImage(game_handle, &exit_data_size, &exit_data);

    bs->FreePool(buf);
    print(out, L"  El juego ha terminado.\r\n");
    while (1) __asm__ volatile ("hlt");

    return EFI_SUCCESS;
}