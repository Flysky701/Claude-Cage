using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Text;

namespace CageLocalTool
{
    internal static unsafe partial class CageLocal
    {
        private const uint WfpPersistent = 1;
        private const uint WfpBlock = 0x1001;
        private const uint WfpPermit = 0x1002;
        private const uint WfpErrNotFound = 0x80320003;
        private const uint WfpErrSublayerNotFound = 0x80320007;
        private const uint WfpErrAlreadyExists = 0x80320009;

        private static readonly Guid WfpCondUserId = new Guid("af043a0a-b34d-4f86-979c-c90371af6e66");
        private static readonly Guid WfpCondRemoteAddress = new Guid("b235ae9a-1d64-49b8-a44c-5ff3d9095045");
        private static readonly Guid WfpCondRemotePort = new Guid("c35a604d-d22b-4e1a-91b4-68f674ee674b");
        private static readonly Guid WfpCondProtocol = new Guid("3971ef2b-623e-4f9a-8cb1-6e79b806b9a7");

        private static readonly Guid WfpLayerConnect4 = new Guid("c38d57d1-05a7-4c33-904f-7fbceee60e82");
        private static readonly Guid WfpLayerConnect6 = new Guid("4a72393b-319f-44bc-84c3-ba54dcb3b6b4");
        private static readonly Guid WfpLayerRecv4 = new Guid("e1cd9fe7-f4b5-4273-96c0-592e487b8650");
        private static readonly Guid WfpLayerRecv6 = new Guid("a3b42c97-9f04-4672-b87e-cee9c483257f");
        private static readonly Guid WfpLayerBind4 = new Guid("1247d66d-0b60-4a15-8d44-7155d0f53a0c");
        private static readonly Guid WfpLayerBind6 = new Guid("55a650e1-5f0a-4eca-a653-88f53b26aa8c");

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct FwpmDisplayData0
        {
            public string name;
            public string description;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpByteBlob
        {
            public uint size;
            public IntPtr data;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpValue0
        {
            public uint type;
            public ulong data;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpmFilterCondition0
        {
            public Guid fieldKey;
            public uint matchType;
            public FwpValue0 conditionValue;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpmAction0
        {
            public uint type;
            public Guid filterType;
        }

        [StructLayout(LayoutKind.Explicit, Size = 16)]
        private struct FwpmFilterContext0
        {
            [FieldOffset(0)]
            public ulong rawContext;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpmSublayer0
        {
            public Guid subLayerKey;
            public FwpmDisplayData0 displayData;
            public uint flags;
            public IntPtr providerKey;
            public FwpByteBlob providerData;
            public ushort weight;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct FwpmFilter0
        {
            public Guid filterKey;
            public FwpmDisplayData0 displayData;
            public uint flags;
            public IntPtr providerKey;
            public FwpByteBlob providerData;
            public Guid layerKey;
            public Guid subLayerKey;
            public FwpValue0 weight;
            public uint numFilterConditions;
            public IntPtr filterCondition;
            public FwpmAction0 action;
            public FwpmFilterContext0 context;
            public IntPtr reserved;
            public ulong filterId;
            public FwpValue0 effectiveWeight;
        }

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmEngineOpen0(
            [MarshalAs(UnmanagedType.LPWStr)] string serverName,
            uint authnService,
            IntPtr authIdentity,
            IntPtr session,
            out IntPtr engineHandle);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmEngineClose0(IntPtr engineHandle);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmTransactionBegin0(IntPtr engineHandle, uint flags);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmTransactionCommit0(IntPtr engineHandle);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmTransactionAbort0(IntPtr engineHandle);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmSubLayerAdd0(IntPtr engineHandle, ref FwpmSublayer0 subLayer, IntPtr sd);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmSubLayerDeleteByKey0(IntPtr engineHandle, ref Guid key);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmFilterAdd0(IntPtr engineHandle, ref FwpmFilter0 filter, IntPtr sd, out ulong id);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmFilterGetByKey0(IntPtr engineHandle, ref Guid key, out IntPtr filter);

        [DllImport("fwpuclnt.dll")]
        private static extern uint FwpmFilterDeleteByKey0(IntPtr engineHandle, ref Guid key);

        [DllImport("fwpuclnt.dll")]
        private static extern void FwpmFreeMemory0(ref IntPtr p);

        internal static Guid DeriveWfpKey(string instanceId, string workerSid, string suffix)
        {
            string input = string.Format("Cage.LocalNative.WFP/v1\0{0}\0{1}\0{2}", instanceId, workerSid, suffix);
            using (SHA256 sha = SHA256.Create())
            {
                byte[] full = sha.ComputeHash(Utf8NoBom.GetBytes(input));
                byte[] guidBytes = new byte[16];
                Array.Copy(full, 0, guidBytes, 0, 16);
                return new Guid(guidBytes);
            }
        }

        private static void CheckWfp(uint status, string operation)
        {
            if (status != 0)
            {
                throw new Win32Exception(unchecked((int)status), string.Format("{0} failed (0x{1:x8})", operation, status));
            }
        }

        private sealed class WfpRuleSpec
        {
            public string Name;
            public Guid Layer;
            public uint Action;
            public ulong Weight;
            public bool UdpOnly;
            public bool BrokerPermit;
        }

        private static WfpRuleSpec[] BuildWfpSpecs()
        {
            ulong blockWeight = ulong.MaxValue - 2;
            ulong permitWeight = ulong.MaxValue;
            return new WfpRuleSpec[]
            {
                new WfpRuleSpec { Name = "connect-v4", Layer = WfpLayerConnect4, Action = WfpBlock, Weight = blockWeight, UdpOnly = false, BrokerPermit = false },
                new WfpRuleSpec { Name = "connect-v6", Layer = WfpLayerConnect6, Action = WfpBlock, Weight = blockWeight, UdpOnly = false, BrokerPermit = false },
                new WfpRuleSpec { Name = "receive-v4", Layer = WfpLayerRecv4, Action = WfpBlock, Weight = blockWeight, UdpOnly = false, BrokerPermit = false },
                new WfpRuleSpec { Name = "receive-v6", Layer = WfpLayerRecv6, Action = WfpBlock, Weight = blockWeight, UdpOnly = false, BrokerPermit = false },
                new WfpRuleSpec { Name = "udp-bind-v4", Layer = WfpLayerBind4, Action = WfpBlock, Weight = blockWeight, UdpOnly = true, BrokerPermit = false },
                new WfpRuleSpec { Name = "udp-bind-v6", Layer = WfpLayerBind6, Action = WfpBlock, Weight = blockWeight, UdpOnly = true, BrokerPermit = false },
                new WfpRuleSpec { Name = "broker-connect-v4", Layer = WfpLayerConnect4, Action = WfpPermit, Weight = permitWeight, UdpOnly = false, BrokerPermit = true }
            };
        }

        private static byte[] BuildUserDescriptorBytes(string workerSid)
        {
            RawSecurityDescriptor sd = new RawSecurityDescriptor(string.Format("D:(A;;CC;;;{0})", workerSid));
            byte[] bytes = new byte[sd.BinaryLength];
            sd.GetBinaryForm(bytes, 0);
            return bytes;
        }

        private static FwpmFilterCondition0[] BuildConditionsForSpec(WfpRuleSpec spec, FwpByteBlob* userBlobPtr, int brokerPort)
        {
            FwpmFilterCondition0 userCond = new FwpmFilterCondition0
            {
                fieldKey = WfpCondUserId,
                matchType = 0,
                conditionValue = new FwpValue0 { type = 14, data = (ulong)userBlobPtr }
            };
            if (spec.BrokerPermit)
            {
                return new FwpmFilterCondition0[]
                {
                    userCond,
                    new FwpmFilterCondition0
                    {
                        fieldKey = WfpCondRemoteAddress,
                        matchType = 0,
                        conditionValue = new FwpValue0 { type = 3, data = 0x7F000001UL }
                    },
                    new FwpmFilterCondition0
                    {
                        fieldKey = WfpCondRemotePort,
                        matchType = 0,
                        conditionValue = new FwpValue0 { type = 2, data = (ulong)(ushort)brokerPort }
                    },
                    new FwpmFilterCondition0
                    {
                        fieldKey = WfpCondProtocol,
                        matchType = 0,
                        conditionValue = new FwpValue0 { type = 1, data = 6UL }
                    }
                };
            }
            if (spec.UdpOnly)
            {
                return new FwpmFilterCondition0[]
                {
                    userCond,
                    new FwpmFilterCondition0
                    {
                        fieldKey = WfpCondProtocol,
                        matchType = 0,
                        conditionValue = new FwpValue0 { type = 1, data = 17UL }
                    }
                };
            }
            return new FwpmFilterCondition0[] { userCond };
        }

        private static bool MatchesWfpFilter(IntPtr ptr, Guid expectedKey, Guid sublayerKey, WfpRuleSpec spec, FwpmFilterCondition0[] expectedConds, byte[] userSdBytes)
        {
            FwpmFilter0 existing = (FwpmFilter0)Marshal.PtrToStructure(ptr, typeof(FwpmFilter0));
            if (existing.filterKey != expectedKey ||
                existing.subLayerKey != sublayerKey ||
                existing.layerKey != spec.Layer ||
                (existing.flags & ~0x40u) != WfpPersistent ||
                existing.action.type != spec.Action ||
                existing.numFilterConditions != (uint)expectedConds.Length ||
                existing.filterCondition == IntPtr.Zero ||
                existing.weight.type != 4 ||
                existing.weight.data == 0 ||
                *(ulong*)existing.weight.data != spec.Weight)
            {
                return false;
            }
            FwpmFilterCondition0* actualConds = (FwpmFilterCondition0*)existing.filterCondition;
            for (int i = 0; i < expectedConds.Length; i++)
            {
                FwpmFilterCondition0 a = actualConds[i];
                FwpmFilterCondition0 e = expectedConds[i];
                if (a.fieldKey != e.fieldKey || a.matchType != e.matchType || a.conditionValue.type != e.conditionValue.type)
                {
                    return false;
                }
                if (e.fieldKey == WfpCondUserId)
                {
                    if (a.conditionValue.data == 0)
                    {
                        return false;
                    }
                    FwpByteBlob* actualBlob = (FwpByteBlob*)a.conditionValue.data;
                    if (actualBlob->size != (uint)userSdBytes.Length || actualBlob->data == IntPtr.Zero)
                    {
                        return false;
                    }
                    byte[] actualSd = new byte[userSdBytes.Length];
                    Marshal.Copy(actualBlob->data, actualSd, 0, actualSd.Length);
                    for (int b = 0; b < userSdBytes.Length; b++)
                    {
                        if (actualSd[b] != userSdBytes[b])
                        {
                            return false;
                        }
                    }
                }
                else if (a.conditionValue.data != e.conditionValue.data)
                {
                    return false;
                }
            }
            return true;
        }

        internal static Dictionary<string, object> WfpApply(string action, string instanceId, string workerSid, int brokerPort)
        {
            if (action != "install" && action != "status" && action != "remove")
            {
                throw new InvalidDataException("Invalid WFP action: " + action);
            }
            Guid sublayerKey = DeriveWfpKey(instanceId, workerSid, "sublayer");
            WfpRuleSpec[] specs = BuildWfpSpecs();
            byte[] userSdBytes = BuildUserDescriptorBytes(workerSid);

            IntPtr engine = IntPtr.Zero;
            CheckWfp(FwpmEngineOpen0(null, 10, IntPtr.Zero, IntPtr.Zero, out engine), "FwpmEngineOpen0");
            try
            {
                fixed (byte* sdPtr = userSdBytes)
                {
                    FwpByteBlob userBlob = new FwpByteBlob { size = (uint)userSdBytes.Length, data = (IntPtr)sdPtr };
                    if (action == "install" || action == "remove")
                    {
                        CheckWfp(FwpmTransactionBegin0(engine, 0), "FwpmTransactionBegin0");
                        bool committed = false;
                        try
                        {
                            if (action == "install")
                            {
                                FwpmSublayer0 sublayer = new FwpmSublayer0
                                {
                                    subLayerKey = sublayerKey,
                                    displayData = new FwpmDisplayData0 { name = "CageLocal " + instanceId, description = "Cage native standard-user isolation sublayer" },
                                    flags = WfpPersistent,
                                    weight = 0x8000
                                };
                                uint addSub = FwpmSubLayerAdd0(engine, ref sublayer, IntPtr.Zero);
                                if (addSub != WfpErrAlreadyExists)
                                {
                                    CheckWfp(addSub, "FwpmSubLayerAdd0");
                                }
                            }

                            for (int i = 0; i < specs.Length; i++)
                            {
                                WfpRuleSpec spec = specs[i];
                                Guid filterKey = DeriveWfpKey(instanceId, workerSid, spec.Name);
                                FwpmFilterCondition0[] conds = BuildConditionsForSpec(spec, &userBlob, brokerPort);
                                IntPtr existing = IntPtr.Zero;
                                uint getRc = FwpmFilterGetByKey0(engine, ref filterKey, out existing);
                                if (getRc == 0)
                                {
                                    try
                                    {
                                        if (!MatchesWfpFilter(existing, filterKey, sublayerKey, spec, conds, userSdBytes))
                                        {
                                            throw new InvalidDataException("WFP filter conflict on " + spec.Name);
                                        }
                                    }
                                    finally
                                    {
                                        FwpmFreeMemory0(ref existing);
                                    }
                                    if (action == "remove")
                                    {
                                        CheckWfp(FwpmFilterDeleteByKey0(engine, ref filterKey), "FwpmFilterDeleteByKey0(" + spec.Name + ")");
                                    }
                                }
                                else if (getRc == WfpErrNotFound)
                                {
                                    if (action == "install")
                                    {
                                        ulong weightVal = spec.Weight;
                                        fixed (FwpmFilterCondition0* condPtr = conds)
                                        {
                                            FwpmFilter0 filter = new FwpmFilter0
                                            {
                                                filterKey = filterKey,
                                                displayData = new FwpmDisplayData0 { name = "CageLocal " + instanceId + " " + spec.Name, description = "CageLocal network rule" },
                                                flags = WfpPersistent,
                                                layerKey = spec.Layer,
                                                subLayerKey = sublayerKey,
                                                weight = new FwpValue0 { type = 4, data = (ulong)&weightVal },
                                                numFilterConditions = (uint)conds.Length,
                                                filterCondition = (IntPtr)condPtr,
                                                action = new FwpmAction0 { type = spec.Action }
                                            };
                                            ulong addedId;
                                            CheckWfp(FwpmFilterAdd0(engine, ref filter, IntPtr.Zero, out addedId), "FwpmFilterAdd0(" + spec.Name + ")");
                                        }
                                    }
                                }
                                else
                                {
                                    CheckWfp(getRc, "FwpmFilterGetByKey0(" + spec.Name + ")");
                                }
                            }

                            if (action == "remove")
                            {
                                uint delSub = FwpmSubLayerDeleteByKey0(engine, ref sublayerKey);
                                if (delSub != WfpErrSublayerNotFound)
                                {
                                    CheckWfp(delSub, "FwpmSubLayerDeleteByKey0");
                                }
                            }

                            CheckWfp(FwpmTransactionCommit0(engine), "FwpmTransactionCommit0");
                            committed = true;
                        }
                        finally
                        {
                            if (!committed)
                            {
                                FwpmTransactionAbort0(engine);
                            }
                        }
                    }

                    int verified = 0;
                    List<string> verifiedNames = new List<string>();
                    for (int i = 0; i < specs.Length; i++)
                    {
                        WfpRuleSpec spec = specs[i];
                        Guid filterKey = DeriveWfpKey(instanceId, workerSid, spec.Name);
                        FwpmFilterCondition0[] conds = BuildConditionsForSpec(spec, &userBlob, brokerPort);
                        IntPtr current = IntPtr.Zero;
                        uint getRc = FwpmFilterGetByKey0(engine, ref filterKey, out current);
                        if (getRc == WfpErrNotFound)
                        {
                            continue;
                        }
                        CheckWfp(getRc, "Verify FwpmFilterGetByKey0(" + spec.Name + ")");
                        try
                        {
                            if (MatchesWfpFilter(current, filterKey, sublayerKey, spec, conds, userSdBytes))
                            {
                                verified++;
                                verifiedNames.Add(spec.Name);
                            }
                        }
                        finally
                        {
                            FwpmFreeMemory0(ref current);
                        }
                    }

                    Dictionary<string, object> summary = new Dictionary<string, object>();
                    summary["action"] = action;
                    summary["instanceId"] = instanceId;
                    summary["workerSid"] = workerSid;
                    summary["brokerPort"] = brokerPort;
                    summary["sublayerKey"] = sublayerKey.ToString("D");
                    summary["installedFilters"] = verified;
                    summary["requiredFilters"] = specs.Length;
                    summary["verifiedRules"] = verifiedNames.ToArray();
                    summary["allVerified"] = (verified == specs.Length);
                    return summary;
                }
            }
            finally
            {
                if (engine != IntPtr.Zero)
                {
                    FwpmEngineClose0(engine);
                }
            }
        }
    }
}
